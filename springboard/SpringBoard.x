#import "../HBLOHandlerController.h"
#import <Cephei/NSDictionary+HBAdditions.h>
#import <Cephei/NSString+HBAdditions.h>
#import <MobileCoreServices/LSApplicationProxy.h>
#import <MobileCoreServices/LSApplicationWorkspace.h>
#import <MobileCoreServices/LSAppLink.h>
#import <SpringBoard/SpringBoard.h>
#import <SpringBoard/SBActivationSettings.h>
#import <SpringBoard/SBApplication.h>
#import <SpringBoard/SBApplicationController.h>
#import <SpringBoard/SBWorkspaceApplication.h>
#import <SpringBoard/SBWorkspaceApplicationTransitionContext.h>
#import <version.h>

typedef void (^HBLOSpringBoardOpenURLCompletion)(NSURL *url, SBApplication *application);

@interface SpringBoard ()

- (void)_opener_applicationOpenURL:(NSURL *)url withApplication:(SBApplication *)application sender:(NSString *)sender activationSettings:(SBActivationSettings *)activationSettings completion:(HBLOSpringBoardOpenURLCompletion)completion;

@end

static BOOL overrideBreadcrumbHax = NO;
static SBActivationSetting activationSettingAppLink = 0;

#pragma mark - SpringBoard hooks

%hook SpringBoard

%new - (void)_opener_applicationOpenURL:(NSURL *)url withApplication:(SBApplication *)application sender:(NSString *)sender activationSettings:(SBActivationSettings *)activationSettings completion:(HBLOSpringBoardOpenURLCompletion)completion {
	// determine if this is an app link override
	BOOL isAppLinkOverride = url && [url.scheme isEqualToString:@"http"] && url.pathComponents.count == 2 && [url.pathComponents[1] isEqualToString:@"_opener_app_link_hax_"];

	// get the application proxy
	LSApplicationProxy *applicationProxy = application.bundleIdentifier ? [LSApplicationProxy applicationProxyForIdentifier:application.bundleIdentifier] : nil;

	// if we don’t know the sender, it might be in the activation settings. try it
	if (!sender && IS_IOS_OR_NEWER(iOS_10_0)) {
		sender = [activationSettings objectForActivationSetting:SBActivationSettingSourceIdentifier];
	}

	// get the replacements. if this is an app link override open, “pretend” we got back the specified
	// url so it won’t be overridden
	NSArray <NSURL *> *replacements = isAppLinkOverride
		? @[ url ]
		: [[HBLOHandlerController sharedInstance] getReplacementsForURL:url application:applicationProxy sender:sender options:nil];

	// no replacements available? just return the original url
	if (!replacements) {
		completion(url, application);
		return;
	}

	NSURL *newURL = replacements[0];

	// determine the apps that own that url’s scheme
	NSArray <LSApplicationProxy *> *appsForScheme = [[LSApplicationWorkspace defaultWorkspace] applicationsAvailableForHandlingURLScheme:newURL.scheme];
	LSApplicationProxy *newApplicationProxy = appsForScheme[0];
	SBApplication *newApplication = nil;

	// get the SBApplication that corresponds to the bundle identifier
	if ([%c(SBApplicationController) instancesRespondToSelector:@selector(applicationWithBundleIdentifier:)]) {
		newApplication = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:newApplicationProxy.applicationIdentifier];
	} else {
		newApplication = [[%c(SBApplicationController) sharedInstance] applicationWithDisplayIdentifier:newApplicationProxy.applicationIdentifier];
	}

	if (!newApplication) {
		// application was nil? welp, give a warning to be sure
		HBLogWarn(@"could not get an SBApplication for url %@", url);
	}

	// if we support app links (iOS 9+), and we did originally have an app, and this isn’t an app link
	// override open
	if (IS_IOS_OR_NEWER(iOS_9_0) && applicationProxy) {
		// if we haven’t already found the position of SBActivationSettingAppLink, do so now. this
		// value has changed a few times before so we cheat and iterate through all key descriptions
		// till we find the matching name
		if (activationSettingAppLink == 0) {
			for (SBActivationSetting i = 0; i < 50; i++) {
				if ([[activationSettings keyDescriptionForSetting:i] isEqualToString:@"appLink"]) {
					activationSettingAppLink = i;
					break;
				}
			}
		}

		// construct an app link for this and configure it in the activation settings for the app
		LSAppLink *appLink = [[%c(LSAppLink) alloc] init];

		// if it’s a web url, use it directly. otherwise we need to do a bit of hax to force the
		// original handler
		if ([url.host isEqualToString:@"http"] || [url.host isEqualToString:@"https"]) {
			appLink.URL = url;
		} else {
			// this url will be picked up by our override handler
			appLink.URL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/_opener_app_link_hax_?%@", applicationProxy.localizedName, @{
				@"url": url.absoluteString
			}.hb_queryString]];
		}

		appLink.targetApplicationProxy = applicationProxy;

		if (activationSettingAppLink != 0) {
			[activationSettings setObject:appLink forActivationSetting:activationSettingAppLink];
		}

		// activate our breadcrumb enabling code
		overrideBreadcrumbHax = YES;
	}

	// wow, we got all this way. pass back the replaced url and app
	completion(newURL, newApplication);
}

%group AngelaAhrendts // 11.0 – 11.1
- (void)applicationOpenURL:(NSURL *)url withApplication:(SBApplication *)application animating:(BOOL)animating activationSettings:(SBActivationSettings *)activationSettings origin:(id)origin withResult:(id)result {
	__block id newResult = [result copy];

	[self _opener_applicationOpenURL:url withApplication:application sender:nil activationSettings:activationSettings completion:^(NSURL *newURL, SBApplication *newApplication) {
		if (newURL) {
			%orig(newURL, newApplication ?: application, animating, activationSettings, origin, newResult);
		}
	}];
}
%end

%group PhilSchiller // 10.0 – 10.3
- (void)applicationOpenURL:(NSURL *)url withApplication:(SBApplication *)application publicURLsOnly:(BOOL)publicURLsOnly animating:(BOOL)animating needsPermission:(BOOL)needsPermission activationSettings:(SBActivationSettings *)activationSettings withResult:(id)result {
	%log;
	__block id newResult = [result copy];

	[self _opener_applicationOpenURL:url withApplication:application sender:nil activationSettings:activationSettings completion:^(NSURL *newURL, SBApplication *newApplication) {
		if (newURL) {
			%orig(newURL, newApplication ?: application, publicURLsOnly, animating, needsPermission, activationSettings, newResult);
		}
	}];
}
%end

%group CraigFederighi // 8.0 – 9.3 (wow, streak!)
- (void)applicationOpenURL:(NSURL *)url withApplication:(SBApplication *)application sender:(NSString *)sender publicURLsOnly:(BOOL)publicURLsOnly animating:(BOOL)animating needsPermission:(BOOL)needsPermission activationSettings:(SBActivationSettings *)activationSettings withResult:(id)result {
	__block id newResult = [result copy];

	[self _opener_applicationOpenURL:url withApplication:application sender:sender activationSettings:activationSettings completion:^(NSURL *newURL, SBApplication *newApplication) {
		if (newURL) {
			%orig(newURL, newApplication ?: application, sender, publicURLsOnly, animating, needsPermission, activationSettings, newResult);
		}
	}];
}
%end

%group JonyIvePointOne // 7.1
- (void)applicationOpenURL:(NSURL *)url withApplication:(SBApplication *)application sender:(NSString *)sender publicURLsOnly:(BOOL)publicURLsOnly animating:(BOOL)animating needsPermission:(BOOL)needsPermission activationContext:(id)context activationHandler:(id)handler {
	__block id newHandler = [handler copy];

	[self _opener_applicationOpenURL:url withApplication:application sender:sender activationSettings:nil completion:^(NSURL *newURL, SBApplication *newApplication) {
		if (newURL) {
			%orig(newURL, newApplication ?: application, sender, publicURLsOnly, animating, needsPermission, context, newHandler);
		}
	}];
}
%end

%group JonyIve // 7.0
- (void)applicationOpenURL:(NSURL *)url withApplication:(SBApplication *)application sender:(NSString *)sender publicURLsOnly:(BOOL)publicURLsOnly animating:(BOOL)animating needsPermission:(BOOL)needsPermission additionalActivationFlags:(id)flags activationHandler:(id)handler {
	__block id newHandler = [handler copy];

	[self _opener_applicationOpenURL:url withApplication:application sender:sender activationSettings:nil completion:^(NSURL *newURL, SBApplication *newApplication) {
		if (newURL) {
			%orig(newURL, newApplication ?: application, sender, publicURLsOnly, animating, needsPermission, flags, newHandler);
		}
	}];
}
%end

%group ScottForstall // 6.0 – 6.1
- (void)applicationOpenURL:(NSURL *)url withApplication:(SBApplication *)application sender:(NSString *)sender publicURLsOnly:(BOOL)publicURLsOnly animating:(BOOL)animating needsPermission:(BOOL)needsPermission additionalActivationFlags:(id)flags {
	[self _opener_applicationOpenURL:url withApplication:application sender:sender activationSettings:nil completion:^(NSURL *newURL, SBApplication *newApplication) {
		if (newURL) {
			%orig(newURL, newApplication ?: application, sender, publicURLsOnly, animating, needsPermission, flags);
		}
	}];
}
%end

%group SteveJobs // 5.0 – 5.1
- (void)applicationOpenURL:(NSURL *)url publicURLsOnly:(BOOL)publicURLsOnly animating:(BOOL)animating sender:(NSString *)sender additionalActivationFlag:(unsigned)flag {
	[self _opener_applicationOpenURL:url withApplication:nil sender:sender activationSettings:nil completion:^(NSURL *newURL, SBApplication *newApplication) {
		if (newURL) {
			%orig(newURL, publicURLsOnly, animating, sender, flag);
		}
	}];
}
%end

%end

#pragma mark - Breadcrumb hax

%group BreadcrumbHax
%hook SBMainDisplaySceneManager

- (BOOL)_shouldBreadcrumbApplication:(SBWorkspaceApplication *)launchedApplication withTransitionContext:(SBWorkspaceApplicationTransitionContext *)transitionContext {
	if (overrideBreadcrumbHax) {
		overrideBreadcrumbHax = NO;

		// get the app we’re about to switch from
		SBWorkspaceApplication *previousApp = [transitionContext previousApplicationForLayoutRole:SBLayoutRoleMainApp];

		// if there was an app (not the home screen), and it’s not the same as the one we’re launching,
		// override to enable breadcrumbs
		return previousApp && ![launchedApplication.bundleIdentifier isEqualToString:previousApp.bundleIdentifier];
	}

	return %orig;
}

%end
%end

#pragma mark - Constructor

%ctor {
	[HBLOHandlerController sharedInstance];

	%init;

	if (IS_IOS_OR_NEWER(iOS_9_0)) {
		%init(BreadcrumbHax);
	}

	if (IS_IOS_OR_NEWER(iOS_11_0)) {
		%init(AngelaAhrendts);
	} else if (IS_IOS_OR_NEWER(iOS_10_0)) {
		%init(PhilSchiller);
	} else if (IS_IOS_OR_NEWER(iOS_8_0)) {
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
