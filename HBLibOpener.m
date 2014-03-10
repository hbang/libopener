/**
 * libopener
 *
 * by HASHBANG Productions <http://hbang.ws>
 * GPL licensed <http://hbang.ws/s/gpl>
 */

#import "HBLibOpener.h"
#import "HBLOGlobal.h"
#import <AppSupport/CPDistributedMessagingCenter.h>
#include <notify.h>
#import <rocketbootstrap/rocketbootstrap.h>

@implementation HBLibOpener {
    NSMutableDictionary *_handlers;
    NSArray *_enabledHandlers;
}

- (instancetype)init {
	self = [super init];

	if (self) {
		_handlers = [[NSMutableDictionary alloc] init];
		_enabledHandlers = [[NSArray alloc] init];

		if (IN_SPRINGBOARD) {
			CPDistributedMessagingCenter *messagingServer = [CPDistributedMessagingCenter centerNamed:kHBLOMessagingCenterName];
            rocketbootstrap_distributedmessagingcenter_apply(messagingServer);
			[messagingServer runServerOnCurrentThread];
			[messagingServer registerForMessageName:kHBLOGetHandlersKey target:self selector:@selector(_receivedMessage:withData:)];
			[messagingServer registerForMessageName:kHBLOGetEnabledHandlersKey target:self selector:@selector(_receivedMessage:withData:)];
		} else {
			[self _preferencesUpdated];
		}
	}

	return self;
}

#pragma mark - Public API

+ (instancetype)sharedInstance {
    static HBLibOpener *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });

    return sharedInstance;
}

- (BOOL)registerHandlerWithName:(NSString *)name block:(NSURL *(^)(NSURL *url))block {
	if (!IN_SPRINGBOARD || _handlers[name]) {
		return NO;
	}

    _handlers[name] = [block copy];
    [self _preferencesUpdated];

	return YES;
}

- (BOOL)handlerIsEnabled:(NSString *)handler {
	return !![_enabledHandlers containsObject:handler];
}

#pragma mark - Private API

- (void)_preferencesUpdated {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		if (IN_SPRINGBOARD) {
			NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:kHBLOPreferencesPath];
			NSMutableArray *newHandlers = [NSMutableArray array];

			for (NSString *handler in _handlers.allKeys) {
				if (!prefs[handler] || ((NSNumber *)prefs[handler]).boolValue) {
					[newHandlers addObject:handler];
				}
			}

			_enabledHandlers = [newHandlers copy];

			notify_post("ws.hbang.libopener/ReloadPrefsApps");
		} else {
            CPDistributedMessagingCenter *center = [CPDistributedMessagingCenter centerNamed:kHBLOMessagingCenterName];
            rocketbootstrap_distributedmessagingcenter_apply(center);
			NSDictionary *callback = [center sendMessageAndReceiveReplyName:kHBLOGetEnabledHandlersKey userInfo:nil];

			if (callback) {
				_enabledHandlers = [callback[kHBLOHandlersKey] copy];
			}
		}
	});
}

- (NSDictionary *)_receivedMessage:(NSString *)message withData:(NSDictionary *)data {
	if (!IN_SPRINGBOARD) {
		return nil;
	}

	if ([message isEqualToString:kHBLOGetHandlersKey]) {
		return @{ kHBLOHandlersKey: _handlers.allKeys };
	} else if ([message isEqualToString:kHBLOGetEnabledHandlersKey]) {
        return @{ kHBLOHandlersKey: _enabledHandlers };
	}

	return nil;
}

#pragma mark - Memory management

- (void)dealloc {
    [_handlers release];
    [_enabledHandlers release];

    [super dealloc];
}

@end
