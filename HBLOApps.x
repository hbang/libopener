#import "HBLOHandlerController.h"
#import "HBLOHandlerChooserViewController.h"
#import <MobileCoreServices/LSApplicationWorkspace.h>
#import <version.h>

BOOL isOverriding = NO;

%hook LSApplicationWorkspace

- (NSURL *)URLOverrideForURL:(NSURL *)url {
	if (isOverriding) {
		return %orig;
	}

	isOverriding = YES;
	NSArray *newURLs = [[HBLOHandlerController sharedInstance] getReplacementsForURL:url sender:[NSBundle mainBundle].bundleIdentifier];
	isOverriding = NO;

	return newURLs ? newURLs[0] : %orig;
}

- (BOOL)openURL:(NSURL *)url withOptions:(NSDictionary *)options {
	if (!IS_IOS_OR_NEWER(iOS_8_0)) {
		return %orig([self URLOverrideForURL:url], options);
	}

	return [[HBLOHandlerChooserController sharedInstance] openURL:url options:options];
}

%end
