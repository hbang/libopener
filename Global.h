#pragma mark - Macros

#if DEBUG
#define HBLOLogDebug(...) HBLogDebug(__VA_ARGS__)
#else
#define HBLOLogDebug(...) if ([HBLOPreferences sharedInstance].debugLoggingEnabled) { \
		HBLogInfo(__VA_ARGS__); \
	}
#endif

#pragma mark - Typedefs

#pragma mark - Constants

static NSString *const HBLOErrorDomain = @"HBLOErrorDomain";

static NSString *const kHBLOHandlersURL = @"file:///Library/Opener";
static NSString *const kHBLOPreferencesPath = @"/var/mobile/Library/Preferences/ws.hbang.libopener.plist";

static NSString *const kHBLOMessagingCenterName = @"ws.hbang.libopener.server";
static NSString *const kHBLOGetHandlersMessage = @"GetHandlers";
static NSString *const kHBLOOpenURLMessage = @"OpenURL";

static NSString *const kHBLOHandlersKey = @"handlers";
static NSString *const kHBLOHandlerNameKey = @"name";
static NSString *const kHBLOHandlerIdentifierKey = @"identifier";
static NSString *const kHBLOHandlerPreferencesBundleKey = @"preferencesBundle";
static NSString *const kHBLOHandlerPreferencesClassKey = @"preferencesClass";
static NSString *const kHBLOOpenURLKey = @"OpenURL";
static NSString *const kHBLOShowChooserKey = @"ShowChooser";
