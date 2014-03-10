#define kHBLOPreferencesPath @"/var/mobile/Library/Preferences/ws.hbang.libopener.plist"

#ifndef IN_SPRINGBOARD
#define IN_SPRINGBOARD ([[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.springboard"])
#endif

BOOL HBLOShouldOverrideOpenURL(NSURL *url);

static NSString *const kHBLOMessagingCenterName = @"ws.hbang.libopener.server";

static NSString *const kHBLOHandlersKey = @"Handlers";
static NSString *const kHBLOGetHandlersKey = @"GetHandlers";
static NSString *const kHBLOGetEnabledHandlersKey = @"GetEnabledHandlers";
