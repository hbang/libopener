#import "HBLOHandlerController.h"
#import <MobileCoreServices/LSApplicationWorkspace.h>
#import <version.h>
#include <dlfcn.h>

BOOL isOverriding = NO;

// TODO: SBSOpenSensitiveURLAndUnlock() late loads MobileCoreServices. not sure
// if it's worth supporting such situations… use case: sbopenurl

@interface LSApplicationWorkspace ()

- (NSURL *)_opener_URLOverrideForURL:(NSURL *)url;

@end

%hook LSApplicationWorkspace

%new - (NSURL *)_opener_URLOverrideForURL:(NSURL *)url {
	NSArray *newURLs = [[HBLOHandlerController sharedInstance] getReplacementsForURL:url sender:[NSBundle mainBundle].bundleIdentifier];

	// none? fair enough, just return the original url
	if (!newURLs || newURLs.count == 0) {
		return nil;
	}

	// well, looks like we're getting newURL[0]! how, uh, boring
	return newURLs[0];
}

- (NSURL *)URLOverrideForURL:(NSURL *)url {
	// if we're currently trying to find replacements, we don't want to replace
	// the replacements
	if (isOverriding) {
		return %orig;
	}

	// consult with HBLOHandlerController to see if there's any possible URL
	// replacements
	isOverriding = YES;
	NSURL *newURL = [self _opener_URLOverrideForURL:url];
	isOverriding = NO;

	// if we got a url, return that. if not, well, we tried… call the original
	// function
	return newURL ?: %orig;
}

%group PreSchiller
- (BOOL)openURL:(NSURL *)url withOptions:(NSDictionary *)options {
	// need to make sure all openURL: requests go through URLOverrideForURL:
	return %orig([self _opener_URLOverrideForURL:url] ?: url, options);
}
%end

%group PhilSchiller
- (BOOL)openURL:(NSURL *)url withOptions:(NSDictionary *)options error:(NSError **)error {
	// need to make sure all openURL: requests go through URLOverrideForURL:
	return %orig([self _opener_URLOverrideForURL:url] ?: url, options, error);
}
%end

%end

#pragma mark - Constructor

%ctor {
	NSURL *executableURL = [NSBundle mainBundle].executableURL;

	// only load these hooks if we’re not in lsd, otherwise we crash in URLOverrideForURL: on iOS 10
	if (![executableURL.path isEqualToString:@"/usr/libexec/lsd"]) {
		%init;

		if (IS_IOS_OR_NEWER(iOS_10_0)) {
			%init(PhilSchiller);
		} else {
			%init(PreSchiller);
		}
	}
}
