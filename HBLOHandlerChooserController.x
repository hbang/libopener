#import "HBLOHandlerChooserController.h"
#import "HBLOHandlerController.h"
#import "springboard/HBLOHandlerChooserViewController.h"
#import <Cephei/HBPreferences.h>
#import <MobileCoreServices/LSApplicationWorkspace.h>
#import <UIKit/UIWindow+Private.h>

@implementation HBLOHandlerChooserController

+ (instancetype)sharedInstance {
    static HBLOHandlerChooserController *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });

    return sharedInstance;
}

#pragma mark - Opening/Preferences

- (BOOL)openURL:(NSURL *)url options:(NSDictionary *)options {
	NSArray *apps = [[LSApplicationWorkspace defaultWorkspace] applicationsAvailableForHandlingURLScheme:url.scheme];

	if (!apps || apps.count < 1) {
		return NO;
	}

	[self presentChooserForURL:url options:options];

	return YES;
}

- (NSString *)_savedDefaultForScheme:(NSString *)scheme {
	return [[HBPreferences preferencesForIdentifier:@"ws.hbang.libopener"] objectForKey:[@"DefaultHandler-" stringByAppendingString:scheme]];
}

- (NSURL *)resolveURLForString:(NSString *)string url:(NSURL *)url {
	HBLogDebug(@"resolveURLForString:%@ url:%@", string, url);
	return url;
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

		HBLOHandlerChooserViewController *viewController = [[[%c(HBLOHandlerChooserViewController) alloc] initWithURL:url openOperationOptions:options] autorelease];
		viewController.completionHandler = ^(NSString *activityType, BOOL completed) {
			window.hidden = YES;

			[window release];
			[navigationController release];
		};

		[window.rootViewController presentViewController:viewController animated:YES completion:nil];
	} else {
		[[HBLOHandlerController sharedInstance] openURL:url];
	}
}

@end
