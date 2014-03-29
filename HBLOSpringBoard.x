#import "HBLOGlobal.h"
#import "HBLOHandlerController.h"
#import <version.h>
#import <SpringBoard/SpringBoard.h>
#import <SpringBoard/SBApplication.h>

%hook SpringBoard

%group SteveJobs

- (void)_openURLCore:(NSURL *)url display:(id)display publicURLsOnly:(BOOL)publicOnly animating:(BOOL)animating additionalActivationFlag:(NSUInteger)flags {
    NSString *sender = ((SpringBoard *)[UIApplication sharedApplication])._accessibilityFrontMostApplication.bundleIdentifier ?: [NSBundle mainBundle].bundleIdentifier;

	if (![[HBLOHandlerController sharedInstance] openURL:url sender:sender]) {
		%orig;
	}
}

%end

%group ScottForstall

- (void)_openURLCore:(NSURL *)url display:(id)display animating:(BOOL)animating sender:(NSString *)sender additionalActivationFlags:(id)flags {
	if (![[HBLOHandlerController sharedInstance] openURL:url sender:sender]) {
		%orig;
	}
}

%end

%group JonyIve

- (void)_openURLCore:(NSURL *)url display:(id)display animating:(BOOL)animating sender:(NSString *)sender additionalActivationFlags:(id)flags activationHandler:(id)handler {
    if (![[HBLOHandlerController sharedInstance] openURL:url sender:sender]) {
        %orig;
    }
}

%end

%end

%ctor {
	if (!IN_SPRINGBOARD) {
        return;
    }

    %init;

    if (IS_IOS_OR_NEWER(iOS_7_0)) {
        %init(JonyIve);
    } else if (IS_IOS_OR_NEWER(iOS_6_0)) {
		%init(ScottForstall);
	} else {
		%init(SteveJobs);
	}
}
