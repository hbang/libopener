#import "HBLOHandlerController.h"

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

- (BOOL)openURL:(NSURL *)url withOptions:(id)options {
	url = [self URLOverrideForURL:url];
	return %orig;
}

%end
