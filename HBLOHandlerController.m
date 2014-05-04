#import "HBLOGlobal.h"
#import "HBLOHandlerController.h"
#import "HBLOHandler.h"
#import <SpringBoard/SpringBoard.h>
#import <SpringBoardServices/SpringBoardServices.h>
#import <AppSupport/CPDistributedMessagingCenter.h>
#import <rocketbootstrap/rocketbootstrap.h>

@implementation HBLOHandlerController {
	NSDictionary *_preferences;
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

		if (IN_SPRINGBOARD) {
			CPDistributedMessagingCenter *messagingServer = [CPDistributedMessagingCenter centerNamed:kHBLOMessagingCenterName];
			rocketbootstrap_distributedmessagingcenter_apply(messagingServer);
			[messagingServer runServerOnCurrentThread];
			[messagingServer registerForMessageName:kHBLOGetHandlersMessage target:self selector:@selector(_receivedMessage:withData:)];
			[messagingServer registerForMessageName:kHBLOOpenURLMessage target:self selector:@selector(_receivedMessage:withData:)];
		}

		[self preferencesUpdated];
	}

	return self;
}

#pragma mark - Registration/loading

- (BOOL)registerHandler:(HBLOHandler *)handler error:(NSError **)error {
	for (HBLOHandler *handler2 in _handlers) {
		if ([handler.identifier isEqualToString:handler2.identifier]) {
			*error = [NSError errorWithDomain:HBLOErrorDomain code:1 userInfo:@{
				NSLocalizedDescriptionKey: [NSString stringWithFormat:@"The handler \"%@\" is already registered.", handler.identifier]
			}];

			return NO;
		}
	}

	[_handlers addObject:handler];
	return YES;
}

- (void)loadHandlers {
	if (_hasLoadedHandlers) {
		NSLog(@"libopener: you only load handlers once (YOLHO)");
		return;
	}

	NSLog(@"libopener: loading handlers");

	_hasLoadedHandlers = YES;

	NSError *error = nil;
	NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[NSURL URLWithString:kHBLOHandlersURL] includingPropertiesForKeys:nil options:kNilOptions error:&error];

	if (error) {
		NSLog(@"libopener: failed to access handler directory %@: %@", kHBLOHandlersURL, error.localizedDescription);
		return;
	}

	for (NSURL *directory in contents) {
		// NSLog is #defined as doing nothing when !DEBUG with my setup
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-variable"
		NSString *baseName = directory.pathComponents.lastObject;
#pragma clang diagnostic pop

		NSLog(@"libopener: loading %@", baseName);

		NSBundle *bundle = [NSBundle bundleWithURL:directory];

		if (!bundle) {
			NSLog(@"libopener: failed to load bundle for handler %@", baseName);
			return;
		}

		[bundle load];

		if (!bundle.principalClass) {
			NSLog(@"libopener: no principal class for handler %@", baseName);
			return;
		}

		HBLOHandler *handler = [[[bundle.principalClass alloc] init] autorelease];

		if (!handler) {
			NSLog(@"libopener: failed to initialise principal class for %@", baseName);
			return;
		}

		NSError *error = nil;

		if (![self registerHandler:handler error:&error]) {
			NSLog(@"libopener: error registering handler %@: %@", baseName, error.localizedDescription);
			return;
		}
	}
}

#pragma mark - Open URL

- (BOOL)openURL:(NSURL *)url sender:(NSString *)sender {
	if (!_hasLoadedHandlers) {
		[self loadHandlers];
	}

	for (HBLOHandler *handler in _handlers) {
		if (![self handlerIsEnabled:handler]) {
			continue;
		}

		NSURL *newUrl = [handler openURL:url sender:sender];

		NSLog(@"got %@ from %@", newUrl, handler);

		if (newUrl) {
			if (IN_SPRINGBOARD) {
				[(SpringBoard *)[UIApplication sharedApplication] applicationOpenURL:newUrl publicURLsOnly:NO];
			} else {
				CPDistributedMessagingCenter *center = [CPDistributedMessagingCenter centerNamed:kHBLOMessagingCenterName];
				rocketbootstrap_distributedmessagingcenter_apply(center);
				[center sendMessageAndReceiveReplyName:kHBLOOpenURLMessage userInfo:@{
					kHBLOOpenURLKey: newUrl.absoluteString
				}];
			}

			return YES;
		}
	}

	return NO;
}

#pragma mark - Preferences

- (void)preferencesUpdated {
	[_preferences release];
	_preferences = [[NSDictionary alloc] initWithContentsOfFile:kHBLOPreferencesPath];
}

- (BOOL)handlerIdentifierIsEnabled:(NSString *)identifier {
	return _preferences[identifier] ? ((NSNumber *)_preferences[identifier]).boolValue : YES;
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
		[(SpringBoard *)[UIApplication sharedApplication] applicationOpenURL:[NSURL URLWithString:data[kHBLOOpenURLKey]] publicURLsOnly:NO];
	}

	return nil;
}

@end
