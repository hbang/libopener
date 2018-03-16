#import "HBLOHandlerController.h"
#import "HBLibOpener.h"
#import "HBLOHandler.h"
#import "HBLOOpenOperation.h"
#import "HBLOPreferences.h"
#import <Cephei/NSString+HBAdditions.h>
#import <MobileCoreServices/LSApplicationWorkspace.h>
#import <MobileCoreServices/LSApplicationProxy.h>
#import <SpringBoard/SpringBoard.h>
#import <SpringBoard/SBApplication.h>
#import <SpringBoardServices/SpringBoardServices.h>
#import <version.h>

#define HBLOAssertOpenerdOnly() \
	if (![self.class isInOpenerd]) { \
		[NSException raise:NSInternalInconsistencyException format:@"-[%@ %@] can only be called within openerd.", self.class, NSStringFromSelector(_cmd)]; \
	}

@implementation HBLOHandlerController {
	BOOL _hasLoadedHandlers;
}

#pragma mark - Helpers

+ (BOOL)isInOpenerd {
	static BOOL isInOpenerd;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		// we’re “in” openerd if we literally are in openerd (or Preferences) on iOS 9 or newer. on
		// older iOS, we’re in-process so this is always YES
		if (IS_IOS_OR_NEWER(iOS_9_0)) {
			NSBundle *bundle = [NSBundle mainBundle];
			isInOpenerd = [bundle.executablePath isEqualToString:@"/usr/libexec/openerd"] || [bundle.bundleIdentifier isEqualToString:@"com.apple.Preferences"];
		} else {
			isInOpenerd = YES;
		}
	});

	return isInOpenerd;
}

+ (NSString *)foregroundBundleIdentifier {
	NSString *sender = nil;

	// get the frontmost app identifier via SBS if in openerd, or directly if in SpringBoard
	if ([self.class isInOpenerd]) {
		sender = SBSCopyFrontmostApplicationDisplayIdentifier();
	} else if (IN_SPRINGBOARD) {
		sender = ((SpringBoard *)[%c(SpringBoard) sharedApplication])._accessibilityFrontMostApplication.bundleIdentifier;
	}

	// if we didn’t get anything and aren’t in openerd, just try the current process’s bundle id
	if (!sender && ![self.class isInOpenerd]) {
		sender = [NSBundle mainBundle].bundleIdentifier;
	}

	// return what we got, or just use springboard as a last resort
	return sender ?: @"com.apple.springboard";
}

#pragma mark - Object

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
	}

	return self;
}

#pragma mark - Registration/loading

- (BOOL)registerHandler:(HBLOHandler *)handler error:(NSError **)error {
	HBLOAssertOpenerdOnly();

	HBLOLogDebug(@"registering handler %@", handler.identifier);

	for (HBLOHandler *handler2 in _handlers) {
		if ([handler.identifier isEqualToString:handler2.identifier]) {
			if (error) {
				*error = [NSError errorWithDomain:HBLOErrorDomain code:1 userInfo:@{
					NSLocalizedDescriptionKey: [NSString stringWithFormat:@"The handler “%@” is already registered.", handler.identifier]
				}];
			}

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
	NSArray <NSURL *> *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:handlersURL includingPropertiesForKeys:nil options:kNilOptions error:&error];

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

- (nullable NSArray <HBLOOpenOperation *> *)getReplacementsForOpenOperation:(HBLOOpenOperation *)openOperation {
	if ([self.class isInOpenerd]) {
		// too easy
		return [self _getReplacementsForOpenOperation:openOperation];
	} else {
		__block NSArray <HBLOOpenOperation *> *output = nil;

		// wrap in a semaphore to ignore the operation if it takes longer than 1 sec. (kind of a hack…)
		dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
		dispatch_queue_t queue = dispatch_queue_create([NSString stringWithFormat:@"ws.hbang.libopener.queue%f", [NSDate date].timeIntervalSince1970].UTF8String, DISPATCH_QUEUE_SERIAL);
		dispatch_async(queue, ^{
			// send the message, and hopefully have it placed in the response buffer
			NSData *input = [NSKeyedArchiver archivedDataWithRootObject:openOperation];
			LMResponseBuffer buffer;
			kern_return_t result = LMConnectionSendTwoWayData(&openerdService, 0, (__bridge CFDataRef)input, &buffer);

			// if it failed, log and return nil
			if (result != KERN_SUCCESS) {
				HBLogError(@"could not contact openerd! error %i", result);
				return;
			}

			// translate the message to NSData, then NSDictionary
			CFDataRef data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, (const UInt8 *)LMMessageGetData(&buffer.message), LMMessageGetDataLength(&buffer.message), kCFAllocatorNull);
			output = [NSKeyedUnarchiver unarchiveObjectWithData:(__bridge NSData *)data];
			LMResponseBufferFree(&buffer);

			dispatch_semaphore_signal(semaphore);
		});

		dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC));

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
		NSDictionary <NSString *, NSString *> *query = url.query.hb_queryStringComponents;

		if (query[@"url"]) {
			url = [NSURL URLWithString:query[@"url"]];
		}
	}

	// no sender given? just set it to our best guess of the foreground app
	if (!sender) {
		openOperation.application = [LSApplicationProxy applicationProxyForIdentifier:[self.class foregroundBundleIdentifier]];
	}

	// load the handlers if we haven't yet
	if (!_hasLoadedHandlers) {
		[self loadHandlers];
	}

	HBLOLogDebug(@"determining replacement for %@ (requested by %@)", url, openOperation.application.applicationIdentifier);

	HBLOPreferences *preferences = [HBLOPreferences sharedInstance];
	NSMutableArray <NSURL *> *results = [NSMutableArray array];

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

	NSMutableArray <HBLOOpenOperation *> *candidates = [NSMutableArray array];

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
