#import "../HBLOHandlerController.h"
#import "../HBLOOpenOperation.h"
#import <Cephei/HBOutputForShellCommand.h>
#import <Cephei/NSString+HBAdditions.h>
#import <FrontBoard/FBSystemService.h>
#import <MobileCoreServices/LSApplicationProxy.h>
#import <MobileCoreServices/LSApplicationWorkspace.h>
#import <MobileCoreServices/LSAppLink.h>
#import <SpringBoard/SpringBoard.h>
#import <SpringBoard/SBActivationSettings.h>
#import <SpringBoard/SBApplication.h>
#import <SpringBoard/SBApplicationController.h>
#import <version.h>

typedef void (^HBLOSpringBoardOpenURLCompletion)(NSURL *url, SBApplication *application);
typedef void (^HBLOFrontBoardLaunchApplicationCompletion)(NSURL *url, NSString *appBundleIdentifier);

@interface SpringBoard ()

- (void)_opener_applicationOpenURL:(NSURL *)url withApplication:(SBApplication *)application sender:(NSString *)sender completion:(HBLOSpringBoardOpenURLCompletion)completion;

@end

//////////////////////////////////////////////////////////////////////
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

@interface BSAuditToken : NSObject <NSCopying>

@property (nonatomic, copy, readonly) NSString *bundleID;
@property (nonatomic, readonly) pid_t pid;

@end
//////////////////////////////////////////////////////////////////////

@interface FBSystemService ()

- (void)_opener_activateURL:(NSURL *)url application:(NSString *)bundleIdentifier options:(FBSOpenApplicationOptions *)options source:(id)source completion:(HBLOFrontBoardLaunchApplicationCompletion)completion;

@end

#pragma mark - Classic hooks

%hook SpringBoard

%new - (void)_opener_applicationOpenURL:(NSURL *)url withApplication:(SBApplication *)application sender:(NSString *)sender completion:(HBLOSpringBoardOpenURLCompletion)completion {
	// get the replacement
	NSArray <HBLOOpenOperation *> *replacements = [[HBLOHandlerController sharedInstance] getReplacementsForOpenOperation:[HBLOOpenOperation openOperationWithURL:url sender:sender]];

	// if there are none, return nothing
	if (!replacements) {
		completion(url, application);
		return;
	}

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

%hook FBSystemService

%group FrontBoard
%new - (void)_opener_activateURL:(NSURL *)url application:(NSString *)bundleIdentifier options:(FBSOpenApplicationOptions *)options source:(id)source completion:(HBLOFrontBoardLaunchApplicationCompletion)completion {
	// on iOS 9, the second arg is a dictionary. on iOS 10+, it’s an object with a dictionary property
	NSMutableDictionary <NSString *, id> *realOptions = (NSMutableDictionary *)([options isKindOfClass:NSDictionary.class] ? options : options.dictionary);
	HBLogDebug(@"options? %@ %@ %@", url, bundleIdentifier, options);

	NSString *sourceBundleIdentifier = [source respondsToSelector:@selector(bundleIdentifier)] ? ((FBSProcessHandle *)source).bundleIdentifier : ((BSAuditToken *)source).bundleID;
	LSAppLink *appLink = realOptions[@"__AppLink4LS"] ?: realOptions[@"__AppLink"];
	NSURL *originalURL = url;

	// if we don’t already have the url (iOS 9+), get the app link url, or the payload url for a
	// traditional url open
	if (!url) {
		originalURL = appLink.URL ?: realOptions[@"__PayloadURL"];
	}

	// if there’s no link, or it’s been forced to browser mode (removed in iOS 11), we have nothing
	// to do here
	if (!originalURL || (!IS_IOS_OR_NEWER(iOS_11_0) && appLink.openStrategy == LSAppLinkOpenStrategyBrowser)) {
		completion(nil, nil);
		return;
	}

	// if this is one of our ugly hack urls, fix it up and remove the app link because our app link is
	// ugglllyyy
	if ([originalURL.scheme isEqualToString:@"https"] && [originalURL.host isEqualToString:@"opener.hbang.ws"] && [originalURL.path isEqualToString:@"/"]) {
		NSDictionary <NSString *, NSString *> *query = originalURL.query.hb_queryStringComponents;
		originalURL = [NSURL URLWithString:query[@"original"]];
		[realOptions removeObjectForKey:@"__AppLink"];
		[realOptions removeObjectForKey:@"__AppLink4LS"];
	}

	// get the replacement
	NSArray <HBLOOpenOperation *> *result = [[HBLOHandlerController sharedInstance] getReplacementsForOpenOperation:[HBLOOpenOperation openOperationWithURL:originalURL sender:sourceBundleIdentifier]];

	// if there are none, we have nothing to do. just call orig and return
	if (!result) {
		completion(nil, nil);
		return;
	}

	// set the app on the app link so the system knows where we redirected to
	if (appLink) {
		appLink.targetApplicationProxy = result[0].application;
	}

	// override the payload url, and remove the user activities (actions)
	realOptions[@"__PayloadURL"] = result[0].URL;
	[realOptions removeObjectForKey:@"__Actions"];

	// get an SBApplication for the app we want to launch
	completion(result[0].URL, result[0].application.applicationIdentifier);
}
%end

%group AngelaAhrendts // 11.0 – 11.1
- (void)activateApplication:(NSString *)bundleIdentifier requestID:(NSUInteger)requestID options:(FBSOpenApplicationOptions *)options source:(FBSProcessHandle *)source originalSource:(FBSProcessHandle *)originalSource withResult:(id)resultBlock {
	[self _opener_activateURL:nil application:bundleIdentifier options:options source:originalSource completion:^(NSURL *url, NSString *appBundleIdentifier) {
		%orig(appBundleIdentifier ?: bundleIdentifier, requestID, options, source, originalSource, resultBlock);
	}];
}
%end

%group PhilSchiller // 10.0 – 10.3
- (void)activateApplication:(NSString *)bundleIdentifier options:(FBSOpenApplicationOptions *)options source:(FBSProcessHandle *)source originalSource:(FBSProcessHandle *)originalSource withResult:(id)resultBlock {
	[self _opener_activateURL:nil application:bundleIdentifier options:options source:originalSource completion:^(NSURL *url, NSString *appBundleIdentifier) {
		%orig(appBundleIdentifier ?: bundleIdentifier, options, source, originalSource, resultBlock);
	}];
}
%end

%group CraigFederighi // 8.0 – 9.3
- (void)activateURL:(NSURL *)url application:(NSString *)bundleIdentifier options:(NSMutableDictionary *)options source:(BSAuditToken *)source originalSource:(BSAuditToken *)originalSource withResult:(id)resultBlock {
	[self _opener_activateURL:url application:bundleIdentifier options:(id)options source:originalSource completion:^(NSURL *url, NSString *appBundleIdentifier) {
		%orig(url, appBundleIdentifier ?: bundleIdentifier, options, source, originalSource, resultBlock);
	}];
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

	// ensure we have a fresh start on respring by stopping openerd. handlers *probably* don’t restart
	// openerd themselves, so we kinda need to do it ourselves
	// TODO: this could use launchd APIs? for now, i’m lazy. ok that’s a lie, i’m always lazy
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		HBOutputForShellCommand(@"/bin/launchctl stop ws.hbang.openerd");
	});

	if (IS_IOS_OR_NEWER(iOS_8_0)) {
		%init(FrontBoard);
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
