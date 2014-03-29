#import "HBLOHandlerController.h"

void HBLOLoadPrefs() {
	[[HBLOHandlerController sharedInstance] preferencesUpdated];
}

%ctor {
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)HBLOLoadPrefs, CFSTR("ws.hbang.libopener/ReloadPrefs"), NULL, kNilOptions);
}
