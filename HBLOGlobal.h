@class HBLOHandlerController;

#ifndef IN_SPRINGBOARD
#define IN_SPRINGBOARD ([[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.springboard"])
#endif

static NSString *const HBLOErrorDomain = @"HBLOErrorDomain";

static NSString *const kHBLOHandlersURL = @"file:///Library/Opener";
static NSString *const kHBLOPreferencesPath = @"/var/mobile/Library/Preferences/ws.hbang.libopener.plist";

static NSString *const kHBLOMessagingCenterName = @"ws.hbang.libopener.server";
static NSString *const kHBLOGetHandlersMessage = @"GetHandlers";
static NSString *const kHBLOOpenURLMessage = @"OpenURL";

static NSString *const kHBLOHandlersKey = @"handlers";
static NSString *const kHBLOHandlerNameKey = @"name";
static NSString *const kHBLOHandlerIdentifierKey = @"identifier";
static NSString *const kHBLOHandlerPreferencesClassKey = @"preferencesClass";
static NSString *const kHBLOOpenURLKey = @"OpenURL";
static NSString *const kHBLOShowChooserKey = @"ShowChooser";
