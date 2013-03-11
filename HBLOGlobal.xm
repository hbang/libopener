/**
 * libopener
 *
 * by HASHBANG Productions <http://hbang.ws>
 * GPL licensed <http://hbang.ws/s/gpl>
 */

#import "HBLOGlobal.h"
#import "HBLibOpener.h"
#import <SpringBoard/SpringBoard.h>

@interface HBLibOpener (Private)
-(void)_preferencesUpdated;
@end

BOOL isHookedValue = NO;

BOOL HBLOShouldOverrideOpenURL(NSURL *url) {
	if (isHookedValue) {
		isHookedValue = NO;
		return NO;
	}

	for (NSString *key in [HBLibOpener sharedInstance].enabledHandlers) {
		NSURL *newUrl = ((NSURL *(^)(NSURL *url))[[HBLibOpener sharedInstance].handlers objectForKey:key])(url);

		if (newUrl) {
			isHookedValue = YES;
			[(SpringBoard *)[%c(SpringBoard) sharedApplication] applicationOpenURL:newUrl publicURLsOnly:NO];
			return YES;
		}
	}

	return NO;
}

void HBLOLoadPrefs() {
	[[HBLibOpener sharedInstance] _preferencesUpdated];
}

%ctor {
	[HBLibOpener sharedInstance];

	if (IN_SPRINGBOARD) {
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)HBLOLoadPrefs, CFSTR("ws.hbang.libopener/ReloadPrefs"), NULL, 0);
	}
}
