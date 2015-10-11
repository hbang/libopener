#import "HBLOGlobal.h"
#import "HBLOHandlerChooserController.h"
#import "HBLOHandlerController.h"
#import "HBLOHandler.h"
#import <AppSupport/CPDistributedMessagingCenter.h>
#import <Cephei/HBPreferences.h>
#import <MobileCoreServices/LSApplicationWorkspace.h>
#import <MobileCoreServices/LSApplicationProxy.h>
#import <MobileCoreServices/NSString+LSAdditions.h>
#import <SpringBoard/SpringBoard.h>
#import <SpringBoard/SBApplication.h>
#import <SpringBoardServices/SpringBoardServices.h>
#import <rocketbootstrap/rocketbootstrap.h>

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

		if (IN_SPRINGBOARD) {
			CPDistributedMessagingCenter *messagingServer = [CPDistributedMessagingCenter centerNamed:kHBLOMessagingCenterName];
			rocketbootstrap_distributedmessagingcenter_apply(messagingServer);
			[messagingServer runServerOnCurrentThread];
			[messagingServer registerForMessageName:kHBLOGetHandlersMessage target:self selector:@selector(_receivedMessage:withData:)];
			[messagingServer registerForMessageName:kHBLOOpenURLMessage target:self selector:@selector(_receivedMessage:withData:)];
		}
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

- (BOOL)openURL:(NSURL *)url {
	if (IN_SPRINGBOARD) {
		return [[UIApplication sharedApplication] openURL:url];
	} else {
		NSArray *apps = [[LSApplicationWorkspace defaultWorkspace] applicationsAvailableForHandlingURLScheme:url.scheme];

		for (LSApplicationProxy *app in apps) {
			if ([app.applicationIdentifier isEqualToString:[NSBundle mainBundle].bundleIdentifier]) {
				return NO;
			}
		}

		CPDistributedMessagingCenter *center = [CPDistributedMessagingCenter centerNamed:kHBLOMessagingCenterName];
		rocketbootstrap_distributedmessagingcenter_apply(center);
		[center sendMessageAndReceiveReplyName:kHBLOOpenURLMessage userInfo:@{
			kHBLOOpenURLKey: url.absoluteString,
			kHBLOShowChooserKey: @YES
		}];

		return YES;
	}
}

- (NSArray *)getReplacementsForURL:(NSURL *)url sender:(NSString *)sender {
	if ([url.scheme isEqualToString:@"googlechrome"] || [url.scheme isEqualToString:@"googlechromes"]) {
		url = [NSURL URLWithString:[@"http" stringByAppendingString:[url.absoluteString substringWithRange:NSMakeRange(12, url.absoluteString.length - 12)]]];
	} else if ([url.scheme isEqualToString:@"googlechrome-x-callback"]) {
		NSDictionary *query = url.query.queryToDict;

		if (query[@"url"]) {
			url = [NSURL URLWithString:query[@"url"]];
		}
	}

	if (!sender) {
		if (IN_SPRINGBOARD) {
			sender = ((SpringBoard *)[UIApplication sharedApplication])._accessibilityFrontMostApplication.bundleIdentifier ?: [NSBundle mainBundle].bundleIdentifier;
		} else {
			sender = [NSBundle mainBundle].bundleIdentifier;
		}
	}

	if (!_hasLoadedHandlers) {
		[self loadHandlers];
	}

	HBLogDebug(@"determining replacement for: %@", url);

	NSMutableArray *results = [NSMutableArray array];

	for (HBLOHandler *handler in _handlers) {
		if (![self handlerIsEnabled:handler]) {
			continue;
		}

		id newURL = [handler openURL:url sender:sender];

		HBLogDebug(@"got %@ from %@", newURL, handler);

		if (!newURL) {
			continue;
		} else if ([newURL isKindOfClass:NSURL.class]) {
			[results addObject:newURL];
		} else if ([newURL isKindOfClass:NSArray.class]) {
			[results addObjectsFromArray:newURL];
		}
	}

	for (NSURL *url_ in results) {
		if (![[UIApplication sharedApplication] canOpenURL:url_]) {
			[results removeObject:url_];
		}
	}

	return results.count ? results : nil;
}

#pragma mark - Preferences

- (BOOL)handlerIdentifierIsEnabled:(NSString *)identifier {
	NSNumber *enabled = [_preferences objectForKey:identifier];
	return enabled ? enabled.boolValue : YES;
}

- (BOOL)handlerIsEnabled:(HBLOHandler *)handler {
	return [self handlerIdentifierIsEnabled:handler.identifier];
}

#pragma mark - Messaging server

- (NSDictionary *)_receivedMessage:(NSString *)message withData:(NSDictionary *)data {
	if (!IN_SPRINGBOARD) {
		return nil;
	}

	if ([message isEqualToString:kHBLOGetHandlersMessage]) {
		[self loadHandlers];

		NSMutableArray *handlers = [NSMutableArray array];

		for (HBLOHandler *handler in _handlers) {
			[handlers addObject:@{
				kHBLOHandlerNameKey: handler.name,
				kHBLOHandlerIdentifierKey: handler.identifier,
				kHBLOHandlerPreferencesClassKey: handler.preferencesClass ?: @""
			}];
		}

		[handlers sortUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
			return [obj1[kHBLOHandlerNameKey] compare:obj2[kHBLOHandlerNameKey]];
		}];

		return @{ kHBLOHandlersKey: handlers };
	} else if ([message isEqualToString:kHBLOOpenURLMessage]) {
		/*if (!data[kHBLOShowChooserKey] || ((NSNumber *)data[kHBLOShowChooserKey]).boolValue) {
			[[HBLOHandlerChooserController sharedInstance] openURL:[NSURL URLWithString:data[kHBLOOpenURLKey]] options:nil];
		} else*/ {
			[self openURL:[NSURL URLWithString:data[kHBLOOpenURLKey]]];
		}
	}

	return nil;
}

@end
