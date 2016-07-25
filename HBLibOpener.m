#import "HBLibOpener.h"
#import "HBLOHandler.h"
#import "HBLOHandlerController.h"
#import "HBLOPreferences.h"
#import <AppSupport/CPDistributedMessagingCenter.h>
#include <notify.h>
#import <rocketbootstrap/rocketbootstrap.h>

@implementation HBLibOpener

#pragma mark - Singleton

+ (instancetype)sharedInstance {
	static HBLibOpener *sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[self alloc] init];
	});

	return sharedInstance;
}

#pragma mark - Public API

- (BOOL)registerHandler:(HBLOHandler *)handler error:(NSError **)error {
	return [[HBLOHandlerController sharedInstance] registerHandler:handler error:error];
}

- (BOOL)registerHandlerWithName:(NSString *)name block:(id)block {
	[NSException raise:NSInternalInconsistencyException format:@"Attempted to register a handler for %@, but legacy Opener 1 handlers are no longer supported. Please contact the developer.", name];
	return NO;
}

- (BOOL)handlerIsEnabled:(NSString *)handler {
	return [[HBLOPreferences sharedInstance] isHandlerIdentifierEnabled:handler];
}

@end
