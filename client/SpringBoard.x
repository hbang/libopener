#import "../HBLOHandlerController.h"
#import "../HBLOOpenOperation.h"
#import <Cephei/NSString+HBAdditions.h>
#import <MobileCoreServices/LSApplicationProxy.h>
#import <MobileCoreServices/LSApplicationWorkspace.h>
#import <MobileCoreServices/LSAppLink.h>
#import <SpringBoard/SpringBoard.h>
#import <SpringBoard/SBActivationSettings.h>
#import <SpringBoard/SBApplication.h>
#import <SpringBoard/SBApplicationController.h>
#import <version.h>

typedef void (^HBLOSpringBoardOpenURLCompletion)(NSURL *url, SBApplication *application);

@interface SpringBoard ()

- (void)_opener_applicationOpenURL:(NSURL *)url withApplication:(SBApplication *)application sender:(NSString *)sender completion:(HBLOSpringBoardOpenURLCompletion)completion;

@end

#pragma mark - Classic hooks

%hook SpringBoard

%new - (void)_opener_applicationOpenURL:(NSURL *)url withApplication:(SBApplication *)application sender:(NSString *)sender completion:(HBLOSpringBoardOpenURLCompletion)completion {	// get the replacement
	NSArray <HBLOOpenOperation *> *replacements = [[HBLOHandlerController sharedInstance] getReplacementsForOpenOperation:[HBLOOpenOperation openOperationWithURL:url sender:sender]];
	HBLOOpenOperation *newOpenOperation = replacements[0];
	SBApplication *newApplication;

	// get the SBApplication that corresponds to the bundle identifier
	if ([%c(SBApplicationController) instancesRespondToSelector:@selector(applicationWithBundleIdentifier:)]) {
		newApplication = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:newOpenOperation.application.applicationIdentifier];
	} else {
		newApplication = [[%c(SBApplicationController) sharedInstance] applicationWithDisplayIdentifier:newOpenOperation.application.applicationIdentifier];
	}

	if (!newApplication) {
		// application was nil? welp, give a warning to be sure
		HBLogWarn(@"could not get an SBApplication for url %@", url);
	}

	// wow, we got all this way. pass back the replaced url and app
	completion(newOpenOperation.URL, newApplication);
}

%group CraigFederighi // 8.0 – 9.3 (wow, streak!)
- (void)applicationOpenURL:(NSURL *)url withApplication:(SBApplication *)application sender:(NSString *)sender publicURLsOnly:(BOOL)publicURLsOnly animating:(BOOL)animating needsPermission:(BOOL)needsPermission activationSettings:(SBActivationSettings *)activationSettings withResult:(id)result {
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

#pragma mark - App Links hooks

@interface FBSOpenApplicationOptions : NSObject <NSCopying>

@property (nonatomic, copy) NSDictionary *dictionary;
@property (nonatomic, retain, readonly) NSURL *url;

+ (instancetype)optionsWithDictionary:(NSDictionary *)dictionary;

@end

typedef NS_ENUM(NSInteger, BSHandleType) {
	BSHandleTypeIdk // TODO
};

@class BSMachPortTaskNameRight;

@interface BSProcessHandle : NSObject

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *bundleIdentifier;
@property (nonatomic, copy) NSString *bundlePath;
@property (nonatomic, copy) NSString *jobLabel;
@property (nonatomic, readonly) pid_t pid;
@property (nonatomic, retain, readonly) BSMachPortTaskNameRight *taskNameRight;
@property (nonatomic, readonly) BSHandleType type;
@property (nonatomic, readonly, getter=isValid) BOOL valid;

@end

@interface FBSProcessHandle : BSProcessHandle

@end

%group AppLink
%hook FBSystemService

- (void)activateApplication:(NSString *)bundleIdentifier options:(FBSOpenApplicationOptions *)options source:(FBSProcessHandle *)source originalSource:(FBSProcessHandle *)originalSource withResult:(id)resultBlock {
	LSAppLink *appLink = options.dictionary[@"__AppLink"];
	NSURL *originalURL = appLink.URL;

	// if there’s no URL involved, we have nothing to do here
	if (!originalURL) {
		%orig;
		return;
	}

	// if this is one of our ugly hack urls, fix it up
	if ([originalURL.scheme isEqualToString:@"https"] && [originalURL.host isEqualToString:@"openerinternal.hbang.ws"] && [originalURL.path isEqualToString:@"/"]) {
		NSDictionary <NSString *, NSString *> *query = originalURL.query.hb_queryStringComponents;
		originalURL = [NSURL URLWithString:query[@"original"]];
	}
	HBLogDebug(@"real url %@", originalURL);

	// get the replacement
	NSArray <HBLOOpenOperation *> *result = [[HBLOHandlerController sharedInstance] getReplacementsForOpenOperation:[HBLOOpenOperation openOperationWithURL:originalURL sender:originalSource.bundleIdentifier]];
	HBLogDebug(@"we got back %@", result);

	// if there are none, we have nothing to do. just call orig and return
	if (!result) {
		%orig;
		return;
	}

	// override the URL on the app link to be something the app can understand
	appLink.URL = result[0].URL;

	// TODO: this definitely does not work, lol

	// get an SBApplication for the app we want to launch
	%orig(result[0].application.applicationIdentifier, options, source, originalSource, resultBlock);
}

%end
%end

#pragma mark - Constructor

%ctor {
	// only use these hooks if we’re in springboard
	if (!IN_SPRINGBOARD) {
		return;
	}

	%init;

	if (IS_IOS_OR_NEWER(iOS_9_0)) {
		%init(AppLink);
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
