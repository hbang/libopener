#import "../HBLOHandlerController.h"
#import "../HBLOOpenOperation.h"
#import <Cephei/NSDictionary+HBAdditions.h>
#import <MobileCoreServices/LSApplicationProxy.h>
#import <MobileCoreServices/LSApplicationWorkspace.h>
#import <MobileCoreServices/LSAppLink.h>
#import <version.h>

typedef void (^LSAppLinkPluginGetAppLinkCompletion)(LSAppLink *appLink, NSError *error);
typedef void (^LSAppLinkPluginGetAppLinksCompletion)(NSArray <LSAppLink *> *appLinks, NSError *error);

@interface _LSAppLinkPlugIn : NSObject

@property (retain) NSURLComponents *URLComponents;

@end

#pragma mark - Hooks

%hook _LSAppLinkPlugIn

+ (NSArray <Class> *)plugInClasses {
	return [@[ %c(HBLOAppLinkPlugin) ] arrayByAddingObjectsFromArray:%orig];
}

%end

#pragma mark - App Link plugin

@interface HBLOAppLinkPlugin : _LSAppLinkPlugIn

- (void)_opener_getAppLinkWithCompletionHandler:(LSAppLinkPluginGetAppLinkCompletion)completion;

@end

%subclass HBLOAppLinkPlugin : _LSAppLinkPlugIn

+ (BOOL)canHandleURLComponents:(NSURLComponents *)urlComponents {
	// we always want to be called, so always return YES
	// TODO: this is inefficient as it seems the plugin class is instantiated each time it’s consulted
	return YES;
}

%new - (void)_opener_getAppLinkWithCompletionHandler:(LSAppLinkPluginGetAppLinkCompletion)completion {
	// construct the URL to use, which must be http(s):// because who knows, reasons
	NSURL *appLinkURL = self.URLComponents.URL;
	
	if (![appLinkURL.scheme isEqualToString:@"http"] && ![appLinkURL.scheme isEqualToString:@"https"]) {
		NSURLComponents *newURLComponents = [[%c(NSURLComponents) alloc] init];
		newURLComponents.scheme = @"http";
		newURLComponents.host = @"opener.hbang.ws";
		newURLComponents.path = @"/_opener_app_link_hax_";
		newURLComponents.queryItems = @[
			[%c(NSURLQueryItem) queryItemWithName:@"original" value:self.URLComponents.URL.absoluteString]
		];
		appLinkURL = newURLComponents.URL;
	}

	// determine the app that’ll open it, which sadly means we need to call through a second time
	NSArray <HBLOOpenOperation *> *result = [[HBLOHandlerController sharedInstance] getReplacementsForOpenOperation:[HBLOOpenOperation openOperationWithURL:self.URLComponents.URL sender:nil]];

	// didn’t get any? return nothing
	if (!result) {
		completion(nil, nil);
		return;
	}

	// create an LSAppLink and provide it back to the app
	NSError *error = nil;
	LSAppLink *appLink;

	if (@available(iOS 11.0, *)) {
		appLink = [%c(LSAppLink) _appLinkWithURL:appLinkURL applicationProxy:result[0].application plugIn:self];
	} else {
		appLink = [%c(LSAppLink) _appLinkWithURL:appLinkURL applicationProxy:result[0].application plugIn:self error:&error];
	}

	completion(appLink, error);
}

%group Ten
- (void)getAppLinkWithCompletionHandler:(LSAppLinkPluginGetAppLinkCompletion)completion {
	[self _opener_getAppLinkWithCompletionHandler:completion];
}
%end

%group Eleven
- (void)getAppLinksWithCompletionHandler:(LSAppLinkPluginGetAppLinksCompletion)completion {
	[self _opener_getAppLinkWithCompletionHandler:^(LSAppLink *appLink, NSError *error) {
		completion(@[ appLink ], error);
	}];
}
%end

%end

#pragma mark - Crash fix

%group CrashFix
%hook LSApplicationWorkspace

- (NSArray *)applicationsAvailableForHandlingURLScheme:(NSString *)urlScheme {
	// not sure why this crashes in lsd, but this seems to “fix” it…
	return [self applicationsAvailableForOpeningURL:[NSURL URLWithString:[urlScheme stringByAppendingString:@"://"]] legacySPI:YES];
}

%end
%end

#pragma mark - Constructor

%ctor {
	if (!IS_IOS_OR_NEWER(iOS_9_0)) {
		return;
	}

	NSString *executablePath = [NSBundle mainBundle].executablePath;
	BOOL isLsd = [executablePath isEqualToString:@"/usr/libexec/lsd"];
	BOOL isOpenerd = [executablePath isEqualToString:@"/usr/libexec/openerd"];

	if (isLsd || isOpenerd) {
		%init(CrashFix);
	}

	// “there’s a daemon called lsd, which i think is the best thing ever” —rpetrich
	if (isLsd) {
		%init;

		if (IS_IOS_OR_NEWER(iOS_11_0)) {
			%init(Eleven);
		} else {
			%init(Ten);
		}
	}
}
