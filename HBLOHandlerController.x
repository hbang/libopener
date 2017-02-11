#import "HBLOHandlerController.h"
#import "HBLOHandler.h"
#import "HBLOPreferences.h"
#import <MobileCoreServices/LSApplicationWorkspace.h>
#import <MobileCoreServices/LSApplicationProxy.h>
#import <MobileCoreServices/NSString+LSAdditions.h>
#import <SpringBoard/SpringBoard.h>
#import <SpringBoard/SBApplication.h>
#import <SpringBoardServices/SpringBoardServices.h>

@implementation HBLOHandlerController {
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
	}

	return self;
}

#pragma mark - Registration/loading

- (BOOL)registerHandler:(HBLOHandler *)handler error:(NSError **)error {
	HBLOLogDebug(@"registering handler %@", handler.identifier);

	for (HBLOHandler *handler2 in _handlers) {
		if ([handler.identifier isEqualToString:handler2.identifier]) {
			HBLogError(@"another handler is registered with this identifier – not registering this one");

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

- (NSArray *)getReplacementsForURL:(NSURL *)url application:(LSApplicationProxy *)application sender:(NSString *)sender options:(NSDictionary *)options {
	// is it a googlechrome(s):// or googlechrome-x-callback:// url?
	if ([url.scheme isEqualToString:@"googlechrome"] || [url.scheme isEqualToString:@"googlechromes"]) {
		// extract the original url from the chrome-specific url
		url = [NSURL URLWithString:[@"http" stringByAppendingString:[url.absoluteString substringWithRange:NSMakeRange(12, url.absoluteString.length - 12)]]];
	} else if ([url.scheme isEqualToString:@"googlechrome-x-callback"]) {
		// grab the url from the query arguments
		NSDictionary *query = url.query.queryToDict;

		if (query[@"url"]) {
			url = [NSURL URLWithString:query[@"url"]];
		}
	}

	// no sender given? just set it to the current app or the foreground app
	if (!sender) {
		if (IN_SPRINGBOARD) {
			sender = ((SpringBoard *)[%c(UIApplication) sharedApplication])._accessibilityFrontMostApplication.bundleIdentifier ?: [NSBundle mainBundle].bundleIdentifier;
		} else {
			sender = [NSBundle mainBundle].bundleIdentifier;
		}
	}

	// load the handlers if we haven't yet
	if (!_hasLoadedHandlers) {
		[self loadHandlers];
	}

	HBLOLogDebug(@"determining replacement for %@ (requested by %@)", url, sender);

	HBLOPreferences *preferences = [HBLOPreferences sharedInstance];

	NSMutableArray *results = [NSMutableArray array];

	// loop over all available handlers
	for (HBLOHandler *handler in _handlers) {
		// not enabled? no worries, just skip over it
		if (![preferences isHandlerEnabled:handler]) {
			continue;
		}

		// ask the handler for a replacement URL
		id newURL = [handler openURL:url sender:sender];

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
			if ([app.applicationIdentifier isEqualToString:sender]) {
				HBLOLogDebug(@"url scheme %@: is supported by the sending app – ignoring", url_.scheme);
				continue;
			}
		}

		// add to the candidates
		[candidates addObject:url_];
	}

	// if we don’t have anything
	if (candidates.count == 0) {
		// we have nothing. return nil
		HBLOLogDebug(@"no candidates available");
		return nil;
	} else if (candidates.count == 1) {
		// if there’s one, log singular
		HBLOLogDebug(@"replacement: %@", candidates[0]);
	} else {
		// if there’s multiple, log plural
		HBLOLogDebug(@"replacements: %@", candidates);
	}

	// return the candidates
	return candidates;
}

- (NSArray *)getReplacementsForURL:(NSURL *)url sender:(NSString *)sender {
	// call through to the more complete method
	return [self getReplacementsForURL:url application:nil sender:sender options:nil];
}

@end
