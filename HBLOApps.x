#import "HBLOHandlerController.h"
#import "HBLOHandlerChooserController.h"
#import <MobileCoreServices/LSApplicationWorkspace.h>
#import <version.h>
#include <dlfcn.h>

BOOL isOverriding = NO;

%group MobileCoreServices
%hook LSApplicationWorkspace

- (NSURL *)URLOverrideForURL:(NSURL *)url {
	%log;
	if (isOverriding) {
		return %orig;
	}

	isOverriding = YES;
	NSArray *newURLs = [[HBLOHandlerController sharedInstance] getReplacementsForURL:url sender:[NSBundle mainBundle].bundleIdentifier];
	isOverriding = NO;

	return newURLs ? newURLs[0] : %orig;
}

- (BOOL)openURL:(NSURL *)url withOptions:(NSDictionary *)options {
	%log;
	if (!IS_IOS_OR_NEWER(iOS_8_0)) {
		return %orig([self URLOverrideForURL:url], options);
	}

	return [[HBLOHandlerChooserController sharedInstance] openURL:url options:options];
}

%end
%end

%ctor {
	%init;

	if (%c(LSApplicationWorkspace)) {
		%init(MobileCoreServices);
	} else {
		HBLogDebug(@"no LSApplicationWorkspace");
	}
}
