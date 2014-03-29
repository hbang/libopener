@class HBLOHandlerController;

#ifndef IN_SPRINGBOARD
#define IN_SPRINGBOARD ([[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.springboard"])
#endif

BOOL HBLOShouldOverrideOpenURL(NSURL *url);

static NSString *const HBLOErrorDomain = @"HBLOErrorDomain";

static NSString *const kHBLOHandlersURL = @"file:///Library/Opener";
static NSString *const kHBLOPreferencesPath = @"/var/mobile/Library/Preferences/ws.hbang.libopener.plist";

static NSString *const kHBLOMessagingCenterName = @"ws.hbang.libopener.server";

static NSString *const kHBLOHandlersKey = @"Handlers";
static NSString *const kHBLOHandlerEnabledKey = @"Enabled";
static NSString *const kHBLOHandlerViewControllerKey = @"ViewController";

static NSString *const kHBLOGetHandlersKey = @"GetHandlers";
static NSString *const kHBLOGetHandlerDataKey = @"GetHandlerData";
