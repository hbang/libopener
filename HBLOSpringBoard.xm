/**
 * libopener
 *
 * by HASHBANG Productions <http://hbang.ws>
 * GPL licensed <http://hbang.ws/s/gpl>
 */

#import "HBLOGlobal.h"
#import <version.h>

%hook SpringBoard

%group SteveJobs

- (void)_openURLCore:(NSURL *)url display:(id)display publicURLsOnly:(BOOL)publicOnly animating:(BOOL)animating additionalActivationFlag:(NSUInteger)flags {
	if (!HBLOShouldOverrideOpenURL(url)) {
		%orig;
	}
}

%end

%group ScottForstall

- (void)_openURLCore:(NSURL *)url display:(id)display animating:(BOOL)animating sender:(id)sender additionalActivationFlags:(id)flags {
	if (!HBLOShouldOverrideOpenURL(url)) {
		%orig;
	}
}

%end

%group JonyIve

- (void)_openURLCore:(NSURL *)url display:(id)display animating:(BOOL)animating sender:(id)sender additionalActivationFlags:(id)flags activationHandler:(id)handler {
    if (!HBLOShouldOverrideOpenURL(url)) {
        %orig;
    }
}

%end

%end

%ctor {
	if (!IN_SPRINGBOARD) {
        return;
    }

    if (IS_IOS_OR_NEWER(iOS_7_0)) {
        %init(SteveJobs);
    } else if (IS_IOS_OR_NEWER(iOS_6_0)) {
		%init(ScottForstall);
	} else {
		%init(JonyIve);
	}
}
