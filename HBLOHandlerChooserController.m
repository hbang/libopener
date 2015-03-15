#import "HBLOHandlerChooserController.h"
#import "HBLOHandlerController.h"
#import <Cephei/HBPreferences.h>

@implementation HBLOHandlerChooserController

- (BOOL)openURL:(NSURL *)url options:(NSDictionary *)options {
	NSArray *apps = [[LSApplicationWorkspace defaultWorkspace] applicationsAvailableForHandlingURLScheme:url.scheme];

	if (!apps || apps.count < 1) {
		return NO;
	}

	[self _presentChooserForURL:url options:options];

	return YES;
}

- (NSString *)_savedDefaultForScheme:(NSString *)scheme {
	return [[HBPreferences preferencesForIdentifier:@"ws.hbang.libopener"] objectForKey:[@"DefaultHandler-" stringByAppendingString:scheme]];
}

- (NSURL *)resolveURLForString:(NSString *)string url:(NSURL *)url {

}

#pragma mark - Chooser

- (void)presentChooserForURL:(NSURL *)url options:(NSDictionary *)options {
	if (IN_SPRINGBOARD) {
		UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
		window.windowLevel = UIWindowLevelAlertReal + 1.f;
		window.hidden = NO;

		UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[[[UIViewController alloc] init] autorelease]];
		navigationController.navigationBarHidden = YES;
		window.rootViewController = navigationController;

		HBLOHandlerChooserViewController *viewController = [[HBLOHandlerChooserViewController alloc] initWithURL:url items:nil];
	} else {
		[[HBLOHandlerController sharedInstance] openURL:url];
	}
}

@end
