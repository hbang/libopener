#import "HBLibOpener.h"
#import "HBLOGlobal.h"
#import "HBLOHandler.h"
#import "HBLOHandlerController.h"
#import "HBLOLegacyHandler.h"
#import <AppSupport/CPDistributedMessagingCenter.h>
#include <notify.h>
#import <rocketbootstrap/rocketbootstrap.h>

@implementation HBLibOpener

#pragma mark - Public API

+ (instancetype)sharedInstance {
    static HBLibOpener *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });

    return sharedInstance;
}

- (BOOL)registerHandlerWithName:(NSString *)name block:(HBLOHandlerCallbackBlock)block {
	if (!IN_SPRINGBOARD) {
		return NO;
	}

    HBLOLegacyHandler *handler = [[[HBLOLegacyHandler alloc] init] autorelease];
    handler.name = name;
    handler.identifier = name;
    handler.legacyBlock = block;

    return [self registerHandler:handler error:nil];
}

- (BOOL)registerHandler:(HBLOHandler *)handler error:(NSError **)error {
    return [[HBLOHandlerController sharedInstance] registerHandler:handler error:error];
}

- (BOOL)handlerIsEnabled:(NSString *)handler {
	return [[HBLOHandlerController sharedInstance] handlerIdentifierIsEnabled:handler];
}

@end
