#import "../HBLOHandlerController.h"
#import <SpringBoard/SpringBoard.h>
#import <SpringBoard/SBApplication.h>
#import <version.h>

#import "HBLOHandlerChooserViewController.h"
#import <UIKit/UIWindow+Private.h>

typedef void (^HBLOSpringBoardOpenURLCompletion)(NSURL *url, SBApplication *application);

@interface SpringBoard ()

- (void)_opener_applicationOpenURL:(NSURL *)url withApplication:(SBApplication *)application sender:(NSString *)sender completion:(HBLOSpringBoardOpenURLCompletion)completion;

@end

%hook SpringBoard

%new - (void)_opener_applicationOpenURL:(NSURL *)url withApplication:(SBApplication *)application sender:(NSString *)sender completion:(HBLOSpringBoardOpenURLCompletion)completion {
	UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	window.windowLevel = UIWindowLevelAlertReal + 1.f;
	window.hidden = NO;

	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[[[UIViewController alloc] init] autorelease]];
	navigationController.navigationBarHidden = YES;
	window.rootViewController = navigationController;

	HBLOHandlerChooserViewController *viewController = [[[%c(HBLOHandlerChooserViewController) alloc] initWithURL:url openOperationOptions:nil] autorelease];
	viewController.completionHandler = ^(NSString *activityType, BOOL completed) {
		window.hidden = YES;

		[window release];
		[navigationController release];

		HBLogDebug(@"activityType = %@, completed = %i",activityType,completed);

		if (completed) {
			completion(url, application);
		}
	};

	[navigationController presentViewController:viewController animated:YES completion:nil];
}

%group CraigFederighi // 8.0 – 9.0 (wow, streak!)
- (void)applicationOpenURL:(NSURL *)url withApplication:(SBApplication *)application sender:(NSString *)sender publicURLsOnly:(BOOL)publicURLsOnly animating:(BOOL)animating needsPermission:(BOOL)needsPermission activationSettings:(id)activationSettings withResult:(id)result {
	%log;

	[self _opener_applicationOpenURL:url withApplication:application sender:sender completion:^(NSURL *newURL, SBApplication *newApplication) {
		HBLogDebug(@"completion(%@, %@)", newURL, newApplication);
		%orig(newURL, newApplication, sender, publicURLsOnly, animating, needsPermission, activationSettings, result);
	}];
}
%end

%group JonyIvePointOne // 7.1
- (void)applicationOpenURL:(NSURL *)url withApplication:(SBApplication *)application sender:(NSString *)sender publicURLsOnly:(BOOL)publicURLsOnly animating:(BOOL)animating needsPermission:(BOOL)needsPermission activationContext:(id)context activationHandler:(id)handler {

}
%end

%group JonyIve // 7.0
- (void)applicationOpenURL:(NSURL *)url withApplication:(SBApplication *)application sender:(NSString *)sender publicURLsOnly:(BOOL)publicURLsOnly animating:(BOOL)animating needsPermission:(BOOL)needsPermission additionalActivationFlags:(id)flags activationHandler:(id)handler {

}
%end

%group ScottForstall // 6.0 – 6.1
- (void)applicationOpenURL:(NSURL *)url withApplication:(SBApplication *)application sender:(NSString *)sender publicURLsOnly:(BOOL)publicURLsOnly animating:(BOOL)animating needsPermission:(BOOL)needsPermission additionalActivationFlags:(id)flags {

}
%end

%group SteveJobs // 5.0 – 5.1
- (void)applicationOpenURL:(NSURL *)url publicURLsOnly:(BOOL)publicURLsOnly animating:(BOOL)animating sender:(NSString *)sender additionalActivationFlag:(unsigned)flag {

}
%end

%end

%ctor {
	[HBLOHandlerController sharedInstance];

	%init;

	if (IS_IOS_OR_NEWER(iOS_8_0)) {
		%init(CraigFederighi);
	} else if (IS_IOS_OR_NEWER(iOS_7_1)) {
		%init(JonyIvePointOne);
	} else if (IS_IOS_OR_NEWER(iOS_7_0)) {
		%init(JonyIve);
	} else if (IS_IOS_OR_NEWER(iOS_6_0)) {
		%init(ScottForstall);
	} else {
		%init(SteveJobs);
	}
}
