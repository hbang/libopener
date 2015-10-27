#import "HBLOHandlerController.h"
#import <MobileCoreServices/LSApplicationWorkspace.h>
#import <version.h>
#include <dlfcn.h>

BOOL isOverriding = NO;

// TODO: SBSOpenSensitiveURLAndUnlock() late loads MobileCoreServices. not sure
// if it's worth supporting such situations… use case: sbopenurl

%hook LSApplicationWorkspace

- (NSURL *)URLOverrideForURL:(NSURL *)url {
	// if we're currently trying to find replacements, we don't want to replace
	// the replacements
	if (isOverriding) {
		return %orig;
	}

	// consult with HBLOHandlerController to see if there's any possible URL
	// replacements
	isOverriding = YES;
	NSArray *newURLs = [[HBLOHandlerController sharedInstance] getReplacementsForURL:url sender:[NSBundle mainBundle].bundleIdentifier];
	isOverriding = NO;

	// none? fair enough, just return the original url
	if (!newURLs || newURLs.count == 0) {
		return %orig;
	}

	// well, looks like we're getting newURL[0]! how, uh, boring
	return newURLs[0];
}

- (BOOL)openURL:(NSURL *)url withOptions:(NSDictionary *)options {
	// need to make sure all openURL: requests go through URLOverrideForURL:
	return %orig([self URLOverrideForURL:url], options);
}

%end
