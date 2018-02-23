#import "HBLOHandlerController.h"
#import "HBLibOpener.h"
#import "HBLOHandler.h"
#import "HBLOOpenOperation.h"
#import "HBLOPreferences.h"
#import <Cephei/NSString+HBAdditions.h>
#import <MobileCoreServices/LSApplicationWorkspace.h>
#import <MobileCoreServices/LSApplicationProxy.h>
#import <SpringBoardServices/SpringBoardServices.h>
#import <version.h>

#define HBLOAssertOpenerdOnly() \
	if (!_isInOpenerd) { \
		[NSException raise:NSInternalInconsistencyException format:@"-[%@ %@] can only be called within openerd.", self.class, NSStringFromSelector(_cmd)]; \
	}

@implementation HBLOHandlerController {
	BOOL _isInOpenerd;
	BOOL _hasLoadedHandlers;
}

+ (instancetype)sharedInstance {
	static HBLOHandlerController *sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[self alloc] init];
	});

	return sharedInstance;
}

- (instancetype)init {
	self = [super init];

	if (self) {
		_handlers = [[NSMutableArray alloc] init];

		// we’re “in” openerd if we literally are in openerd (or Preferences) on iOS 9 or newer. on
		// older iOS, we’re in-process so this is always YES
		if (IS_IOS_OR_NEWER(iOS_9_0)) {
			NSBundle *bundle = [NSBundle mainBundle];
			_isInOpenerd = [bundle.executablePath isEqualToString:@"/usr/libexec/openerd"] || [bundle.bundleIdentifier isEqualToString:@"com.apple.Preferences"];
		} else {
			_isInOpenerd = YES;
		}
	}

	return self;
}

#pragma mark - Registration/loading

- (BOOL)registerHandler:(HBLOHandler *)handler error:(NSError **)error {
	HBLOAssertOpenerdOnly();

	HBLOLogDebug(@"registering handler %@", handler.identifier);

	for (HBLOHandler *handler2 in _handlers) {
		if ([handler.identifier isEqualToString:handler2.identifier]) {
			*error = [NSError errorWithDomain:HBLOErrorDomain code:1 userInfo:@{
				NSLocalizedDescriptionKey: [NSString stringWithFormat:@"The handler “%@” is already registered.", handler.identifier]
			}];

			return NO;
		}
	}

	[_handlers addObject:handler];
	return YES;
}

- (void)loadHandlers {
	HBLOAssertOpenerdOnly();

	if (_hasLoadedHandlers) {
		HBLOLogDebug(@"you only load handlers once (YOLHO)");
		return;
	}

	HBLOLogDebug(@"loading handlers");

	_hasLoadedHandlers = YES;

	NSURL *handlersURL = [NSURL URLWithString:kHBLOHandlersURL].URLByResolvingSymlinksInPath;

	NSError *error = nil;
	NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:handlersURL includingPropertiesForKeys:nil options:kNilOptions error:&error];

	if (error) {
		HBLogError(@"failed to access handler directory %@: %@", kHBLOHandlersURL, error.localizedDescription);
		return;
	}

	for (NSURL *directory in contents) {
		NSString *baseName = directory.pathComponents.lastObject;

		HBLOLogDebug(@"loading %@", baseName);

		NSBundle *bundle = [NSBundle bundleWithURL:directory];

		if (!bundle) {
			HBLogError(@"failed to load bundle for handler %@", baseName);
			continue;
		}

		[bundle load];

		if (!bundle.principalClass) {
			HBLogError(@"no principal class for handler %@", baseName);
			continue;
		}

		HBLOHandler *handler = [[bundle.principalClass alloc] init];

		if (!handler) {
			HBLogError(@"failed to initialise principal class for %@", baseName);
			continue;
		}

		NSError *error = nil;

		if (![self registerHandler:handler error:&error]) {
			HBLogError(@"error registering handler %@: %@", baseName, error.localizedDescription);
			continue;
		}
	}
}

#pragma mark - Open URL

- (NSString *)foregroundBundleIdentifier {
	NSString *sender = nil;

	// if in springboard or openerd, ask SpringBoardServices for the frontmost app identifier
	if (IN_SPRINGBOARD || _isInOpenerd) {
		sender = SBSCopyFrontmostApplicationDisplayIdentifier();
	}

	// if we didn’t get anything and aren’t in openerd, just try the current process’s bundle id
	if (!sender && !_isInOpenerd) {
		sender = [NSBundle mainBundle].bundleIdentifier;
	}

	// return what we got, or just use springboard as a last resort
	return sender ?: @"com.apple.springboard";
}

- (nullable NSArray <HBLOOpenOperation *> *)getReplacementsForOpenOperation:(HBLOOpenOperation *)openOperation {
	if (_isInOpenerd) {
		// too easy
		return [self _getReplacementsForOpenOperation:openOperation];
	} else {
		// send the message, and hopefully have it placed in the response buffer
		NSData *input = [NSKeyedArchiver archivedDataWithRootObject:openOperation];
		LMResponseBuffer buffer;
		kern_return_t result = LMConnectionSendTwoWayData(&openerdService, 0, (__bridge CFDataRef)input, &buffer);

		// if it failed, log and return nil
		if (result != KERN_SUCCESS) {
			HBLogError(@"could not contact openerd! error %i", result);
			return nil;
		}

		// translate the message to NSData, then NSDictionary
		CFDataRef data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, (const UInt8 *)LMMessageGetData(&buffer.message), LMMessageGetDataLength(&buffer.message), kCFAllocatorNull);
		NSArray <HBLOOpenOperation *> *output = [NSKeyedUnarchiver unarchiveObjectWithData:(__bridge NSData *)data];
		LMResponseBufferFree(&buffer);

		// return what we got, or nothing if we got nothing
		return output && output.count > 0 ? output : nil;
	}
}

- (nullable NSArray <HBLOOpenOperation *> *)_getReplacementsForOpenOperation:(HBLOOpenOperation *)openOperation {
	HBLOAssertOpenerdOnly();

	NSURL *url = openOperation.URL;
	NSString *sender = openOperation.application.applicationIdentifier;

	// is it a googlechrome(s):// or googlechrome-x-callback:// url?
	if ([url.scheme isEqualToString:@"googlechrome"] || [url.scheme isEqualToString:@"googlechromes"]) {
		// extract the original url from the chrome-specific url
		url = [NSURL URLWithString:[@"http" stringByAppendingString:[url.absoluteString substringWithRange:NSMakeRange(12, url.absoluteString.length - 12)]]];
	} else if ([url.scheme isEqualToString:@"googlechrome-x-callback"]) {
		// grab the url from the query arguments
		NSDictionary *query = url.query.hb_queryStringComponents;

		if (query[@"url"]) {
			url = [NSURL URLWithString:query[@"url"]];
		}
	}

	// no sender given? just set it to our best guess of the foreground app
	if (!sender) {
		openOperation.application = [LSApplicationProxy applicationProxyForIdentifier:self.foregroundBundleIdentifier];
	}

	// load the handlers if we haven't yet
	if (!_hasLoadedHandlers) {
		[self loadHandlers];
	}

	HBLOLogDebug(@"determining replacement for %@ (requested by %@)", url, openOperation.application.applicationIdentifier);

	HBLOPreferences *preferences = [HBLOPreferences sharedInstance];
	NSMutableArray *results = [NSMutableArray array];

	// loop over all available handlers
	for (HBLOHandler *handler in _handlers) {
		// not enabled? no worries, just skip over it
		if (![preferences isHandlerEnabled:handler]) {
			HBLOLogDebug(@" → %@ is disabled", handler.identifier);
			continue;
		}

		// ask the handler for a replacement URL
		id newURL = [handler openURL:url sender:openOperation.application.applicationIdentifier];

		HBLOLogDebug(@" → %@ returned: %@", handler.identifier, newURL);

		if (!newURL) {
			// nothing returned? skip to the next handler
			continue;
		} else if ([newURL isKindOfClass:NSURL.class]) {
			// it's an NSURL? add that to our results
			[results addObject:newURL];
		} else if ([newURL isKindOfClass:NSArray.class]) {
			// it's an array, hopefully of NSURLs? add them to our results
			[results addObjectsFromArray:newURL];
		} else {
			HBLogError(@"%@ returned invalid value of type %@: %@", handler.identifier, ((NSObject *)newURL).class, newURL);
		}
	}

	NSMutableArray *candidates = [NSMutableArray array];

	// iterate over our results
	for (NSURL *url_ in results) {
		NSArray <LSApplicationProxy *> *apps = [[LSApplicationWorkspace defaultWorkspace] applicationsAvailableForHandlingURLScheme:url_.scheme];

		// if nothing can open that url scheme, we don't want it (sorry)
		if (apps.count == 0) {
			continue;
		}

		// if the url can be opened by the same app, we should ignore it
		for (LSApplicationProxy *app in apps) {
			if ([app isEqual:openOperation.application]) {
				HBLOLogDebug(@"url scheme %@: is supported by the sending app – ignoring", url_.scheme);
				continue;
			}

			// add it to the candidates
			[candidates addObject:[HBLOOpenOperation openOperationWithURL:url_ application:app]];
		}
	}

	// if we don’t have anything, log and return nil. if we do, log that and return the array
	if (candidates.count == 0) {
		HBLOLogDebug(@"no candidates available");
		return nil;
	} else {
		HBLOLogDebug(@"replacements: %@", candidates);
		return candidates;
	}
}

@end
