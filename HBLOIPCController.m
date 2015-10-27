#import "HBLOIPCController.h"
#import "HBLOHandler.h"
#import "HBLOHandlerController.h"
#import <AppSupport/CPDistributedMessagingCenter.h>
#import <rocketbootstrap/rocketbootstrap.h>

@implementation HBLOIPCController

+ (instancetype)sharedInstance {
	static HBLOIPCController *sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[self alloc] init];
	});

	return sharedInstance;
}

- (instancetype)init {
	if (IN_SPRINGBOARD) {
		return nil;
	}

	self = [super init];

	if (self) {
		CPDistributedMessagingCenter *messagingServer = [CPDistributedMessagingCenter centerNamed:kHBLOMessagingCenterName];
		rocketbootstrap_distributedmessagingcenter_apply(messagingServer);
		[messagingServer runServerOnCurrentThread];
		[messagingServer registerForMessageName:kHBLOGetHandlersMessage target:self selector:@selector(_receivedMessage:withData:)];
	}

	return self;
}

#pragma mark - Messaging server

- (NSDictionary *)_receivedMessage:(NSString *)message withData:(NSDictionary *)data {
	HBLOHandlerController *handlerController = [HBLOHandlerController sharedInstance];

	if ([message isEqualToString:kHBLOGetHandlersMessage]) {
		[handlerController loadHandlers];

		NSMutableArray *handlers = [NSMutableArray array];

		for (HBLOHandler *handler in handlerController.handlers) {
			[handlers addObject:@{
				kHBLOHandlerNameKey: handler.name,
				kHBLOHandlerIdentifierKey: handler.identifier,
				kHBLOHandlerPreferencesBundleKey: handler.preferencesBundle ? handler.preferencesBundle.bundleURL.absoluteString : @"",
				kHBLOHandlerPreferencesClassKey: handler.preferencesClass ?: @""
			}];
		}

		[handlers sortUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
			return [obj1[kHBLOHandlerNameKey] compare:obj2[kHBLOHandlerNameKey]];
		}];

		return @{ kHBLOHandlersKey: handlers };
	}

	return nil;
}

@end
