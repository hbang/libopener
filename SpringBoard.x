#import "HBLOHandlerController.h"
#import <MobileCoreServices/LSApplicationProxy.h>
#import <MobileCoreServices/LSApplicationWorkspace.h>
#import <SpringBoard/SpringBoard.h>
#import <SpringBoard/SBApplication.h>
#import <SpringBoard/SBApplicationController.h>
#import <version.h>

typedef void (^HBLOSpringBoardOpenURLCompletion)(NSURL *url, SBApplication *application);

@interface SpringBoard ()

- (void)_opener_applicationOpenURL:(NSURL *)url withApplication:(SBApplication *)application sender:(NSString *)sender completion:(HBLOSpringBoardOpenURLCompletion)completion;

@end

#pragma mark - SpringBoard hooks

%hook SpringBoard

%new - (void)_opener_applicationOpenURL:(NSURL *)url withApplication:(SBApplication *)application sender:(NSString *)sender completion:(HBLOSpringBoardOpenURLCompletion)completion {
	// get the application proxy
	LSApplicationProxy *applicationProxy = application.bundleIdentifier ? [LSApplicationProxy applicationProxyForIdentifier:application.bundleIdentifier] : nil;

	// get the replacements
	NSArray <NSURL *> *replacements = [[HBLOHandlerController sharedInstance] getReplacementsForURL:url application:applicationProxy sender:sender options:nil];

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

	// wow, we got all this way. pass back the replaced url and app
	completion(newURL, newApplication);
}

%group AngelaAhrendts // 11.0 – 11.1
- (void)applicationOpenURL:(NSURL *)url withApplication:(SBApplication *)application animating:(BOOL)animating activationSettings:(id)activationSettings origin:(id)origin withResult:(id)result {
	__block id newResult = [result copy];

	// TODO: origin is probably an SBApplication? maybe a string again? please? pleeeease?
	[self _opener_applicationOpenURL:url withApplication:application sender:nil completion:^(NSURL *newURL, SBApplication *newApplication) {
		if (newURL) {
			%orig(newURL, newApplication ?: application, animating, activationSettings, origin, newResult);
		}
	}];
}
%end

%group PhilSchiller // 10.0 – 10.3
- (void)applicationOpenURL:(NSURL *)url withApplication:(SBApplication *)application publicURLsOnly:(BOOL)publicURLsOnly animating:(BOOL)animating needsPermission:(BOOL)needsPermission activationSettings:(id)activationSettings withResult:(id)result {
	__block id newResult = [result copy];

	// TODO: kinda rushing… find out how to get the sender
	[self _opener_applicationOpenURL:url withApplication:application sender:nil completion:^(NSURL *newURL, SBApplication *newApplication) {
		if (newURL) {
			%orig(newURL, newApplication ?: application, publicURLsOnly, animating, needsPermission, activationSettings, newResult);
		}
	}];
}
%end

%group CraigFederighi // 8.0 – 9.3 (wow, streak!)
- (void)applicationOpenURL:(NSURL *)url withApplication:(SBApplication *)application sender:(NSString *)sender publicURLsOnly:(BOOL)publicURLsOnly animating:(BOOL)animating needsPermission:(BOOL)needsPermission activationSettings:(id)activationSettings withResult:(id)result {
	__block id newResult = [result copy];

	[self _opener_applicationOpenURL:url withApplication:application sender:sender completion:^(NSURL *newURL, SBApplication *newApplication) {
		if (newURL) {
			%orig(newURL, newApplication ?: application, sender, publicURLsOnly, animating, needsPermission, activationSettings, newResult);
		}
	}];
}
%end

%group JonyIvePointOne // 7.1
- (void)applicationOpenURL:(NSURL *)url withApplication:(SBApplication *)application sender:(NSString *)sender publicURLsOnly:(BOOL)publicURLsOnly animating:(BOOL)animating needsPermission:(BOOL)needsPermission activationContext:(id)context activationHandler:(id)handler {
	__block id newHandler = [handler copy];

	[self _opener_applicationOpenURL:url withApplication:application sender:sender completion:^(NSURL *newURL, SBApplication *newApplication) {
		if (newURL) {
			%orig(newURL, newApplication ?: application, sender, publicURLsOnly, animating, needsPermission, context, newHandler);
		}
	}];
}
%end

%group JonyIve // 7.0
- (void)applicationOpenURL:(NSURL *)url withApplication:(SBApplication *)application sender:(NSString *)sender publicURLsOnly:(BOOL)publicURLsOnly animating:(BOOL)animating needsPermission:(BOOL)needsPermission additionalActivationFlags:(id)flags activationHandler:(id)handler {
	__block id newHandler = [handler copy];

	[self _opener_applicationOpenURL:url withApplication:application sender:sender completion:^(NSURL *newURL, SBApplication *newApplication) {
		if (newURL) {
			%orig(newURL, newApplication ?: application, sender, publicURLsOnly, animating, needsPermission, flags, newHandler);
		}
	}];
}
%end

%group ScottForstall // 6.0 – 6.1
- (void)applicationOpenURL:(NSURL *)url withApplication:(SBApplication *)application sender:(NSString *)sender publicURLsOnly:(BOOL)publicURLsOnly animating:(BOOL)animating needsPermission:(BOOL)needsPermission additionalActivationFlags:(id)flags {
	[self _opener_applicationOpenURL:url withApplication:application sender:sender completion:^(NSURL *newURL, SBApplication *newApplication) {
		if (newURL) {
			%orig(newURL, newApplication ?: application, sender, publicURLsOnly, animating, needsPermission, flags);
		}
	}];
}
%end

%group SteveJobs // 5.0 – 5.1
- (void)applicationOpenURL:(NSURL *)url publicURLsOnly:(BOOL)publicURLsOnly animating:(BOOL)animating sender:(NSString *)sender additionalActivationFlag:(unsigned)flag {
	[self _opener_applicationOpenURL:url withApplication:nil sender:sender completion:^(NSURL *newURL, SBApplication *newApplication) {
		if (newURL) {
			%orig(newURL, publicURLsOnly, animating, sender, flag);
		}
	}];
}
%end

%end

#pragma mark - Constructor

%ctor {
	if (!IN_SPRINGBOARD) {
		return;
	}

	[HBLOHandlerController sharedInstance];

	%init;

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
