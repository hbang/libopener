#import "HBLOPreferences.h"
#import "HBLOHandler.h"
#import <Cephei/HBPreferences.h>

@implementation HBLOPreferences {
	HBPreferences *_preferences;
}

#pragma mark - Singleton

+ (instancetype)sharedInstance {
	static HBLOPreferences *sharedInstance;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[HBLOPreferences alloc] init];
	});

	return sharedInstance;
}

#pragma mark - Init

- (instancetype)init {
	self = [super init];

	if (self) {
		_preferences = [HBPreferences preferencesForIdentifier:@"ws.hbang.libopener"];
		[_preferences registerBool:&_debugLoggingEnabled default:NO forKey:@"_DebugLogging"];
	}

	return self;
}

#pragma mark - Preferences

- (BOOL)isHandlerEnabled:(HBLOHandler *)handler {
	if (handler.preferencesBundle && handler.preferencesClass) {
		return YES;
	} else {
		return [self isHandlerIdentifierEnabled:handler.identifier];
	}
}

- (BOOL)isHandlerIdentifierEnabled:(NSString *)identifier {
	NSNumber *enabled = [_preferences objectForKey:identifier];
	return enabled ? enabled.boolValue : YES;
}

@end
