#import "HBLOHandlerController.h"
#import "HBLOHandler.h"
#import <Cephei/HBPreferences.h>
#import <MobileCoreServices/LSApplicationWorkspace.h>
#import <MobileCoreServices/LSApplicationProxy.h>
#import <MobileCoreServices/NSString+LSAdditions.h>
#import <SpringBoard/SpringBoard.h>
#import <SpringBoard/SBApplication.h>
#import <SpringBoardServices/SpringBoardServices.h>

@implementation HBLOHandlerController {
	HBPreferences *_preferences;
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
		_preferences = [[HBPreferences alloc] initWithIdentifier:@"ws.hbang.libopener"];
	}

	return self;
}

#pragma mark - Registration/loading

- (BOOL)registerHandler:(HBLOHandler *)handler error:(NSError **)error {
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
	if (_hasLoadedHandlers) {
		HBLogDebug(@"you only load handlers once (YOLHO)");
		return;
	}

	HBLogInfo(@"loading handlers");

	_hasLoadedHandlers = YES;

	NSError *error = nil;
	NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[NSURL URLWithString:kHBLOHandlersURL] includingPropertiesForKeys:nil options:kNilOptions error:&error];

	if (error) {
		HBLogError(@"failed to access handler directory %@: %@", kHBLOHandlersURL, error.localizedDescription);
		return;
	}

	for (NSURL *directory in contents) {
		NSString *baseName = directory.pathComponents.lastObject;

		HBLogInfo(@"loading %@", baseName);

		NSBundle *bundle = [NSBundle bundleWithURL:directory];

		if (!bundle) {
			HBLogError(@"failed to load bundle for handler %@", baseName);
			return;
		}

		[bundle load];

		if (!bundle.principalClass) {
			HBLogError(@"no principal class for handler %@", baseName);
			return;
		}

		HBLOHandler *handler = [[[bundle.principalClass alloc] init] autorelease];

		if (!handler) {
			HBLogError(@"libopener: failed to initialise principal class for %@", baseName);
			return;
		}

		NSError *error = nil;

		if (![self registerHandler:handler error:&error]) {
			HBLogError(@"libopener: error registering handler %@: %@", baseName, error.localizedDescription);
			return;
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
			sender = ((SpringBoard *)[UIApplication sharedApplication])._accessibilityFrontMostApplication.bundleIdentifier ?: [NSBundle mainBundle].bundleIdentifier;
		} else {
			sender = [NSBundle mainBundle].bundleIdentifier;
		}
	}

	// load the handlers if we haven't yet
	if (!_hasLoadedHandlers) {
		[self loadHandlers];
	}

	HBLogDebug(@"determining replacement for: %@", url);

	NSMutableArray *results = [NSMutableArray array];

	// loop over all available handlers
	for (HBLOHandler *handler in _handlers) {
		// not enabled? no worries, just skip over it
		if (![self handlerIsEnabled:handler]) {
			continue;
		}

		// ask the handler for a replacement URL
		id newURL = [handler openURL:url sender:sender];

		HBLogDebug(@"got %@ from %@", newURL, handler);

		if (!newURL) {
			// nothing returned? skip to the next handler
			continue;
		} else if ([newURL isKindOfClass:NSURL.class]) {
			// it's an NSURL? add that to our results
			[results addObject:newURL];
		} else if ([newURL isKindOfClass:NSArray.class]) {
			// it's an array, hopefully of NSURLs? add them to our results
			[results addObjectsFromArray:newURL];
		}
	}

	// iterate over our results
	for (NSURL *url_ in results) {
		NSArray <LSApplicationProxy *> *apps = [[LSApplicationWorkspace defaultWorkspace] applicationsAvailableForHandlingURLScheme:url.scheme];

		if (apps.count == 0) {
			// if nothing can open that url scheme, remove it
			[results removeObject:url_];
		} else {
			// if the url can be opened by the same app, we should ignore it
			for (LSApplicationProxy *app in apps) {
				if ([app.applicationIdentifier isEqualToString:sender]) {
					[results removeObject:url_];
					break;
				}
			}
		}
	}

	// if we have results, return them, else return nil
	return results.count ? results : nil;
}

- (NSArray *)getReplacementsForURL:(NSURL *)url sender:(NSString *)sender {
	// call through to the more complete method
	return [self getReplacementsForURL:url application:nil sender:sender options:nil];
}

#pragma mark - Preferences

- (BOOL)handlerIdentifierIsEnabled:(NSString *)identifier {
	NSNumber *enabled = [_preferences objectForKey:identifier];
	return enabled ? enabled.boolValue : YES;
}

- (BOOL)handlerIsEnabled:(HBLOHandler *)handler {
	return [self handlerIdentifierIsEnabled:handler.identifier];
}

@end
