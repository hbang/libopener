#define PREFS_PATH @"/var/mobile/Library/Preferences/ws.hbang.libopener.plist"
#define IN_SPRINGBOARD ([[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.springboard"])

BOOL HBLOShouldOverrideOpenURL(NSURL *url);
