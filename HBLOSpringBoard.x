#import "HBLOGlobal.h"
#import "HBLOHandlerController.h"
#import <version.h>
#import <SpringBoard/SpringBoard.h>
#import <SpringBoard/SBApplication.h>

BOOL isHookedValue = NO;

BOOL HBLOOpenURLCoreHook(NSURL *url, NSString *sender) {
	if (isHookedValue) {
		isHookedValue = NO;
	} else if ([[HBLOHandlerController sharedInstance] openURL:url sender:sender]) {
		isHookedValue = YES;
		return NO;
	}

	return YES;
}

%hook SpringBoard

%group SteveJobs

- (void)_openURLCore:(NSURL *)url display:(id)display publicURLsOnly:(BOOL)publicOnly animating:(BOOL)animating additionalActivationFlag:(NSUInteger)flags {
	NSString *sender = ((SpringBoard *)[UIApplication sharedApplication])._accessibilityFrontMostApplication.bundleIdentifier ?: [NSBundle mainBundle].bundleIdentifier;

	if (HBLOOpenURLCoreHook(url, sender)) {
		%orig;
	}
}

%end

%group ScottForstall

- (void)_openURLCore:(NSURL *)url display:(id)display animating:(BOOL)animating sender:(NSString *)sender additionalActivationFlags:(id)flags {
	if (HBLOOpenURLCoreHook(url, sender)) {
		%orig;
	}
}

%end

%group JonyIve

- (void)_openURLCore:(NSURL *)url display:(id)display animating:(BOOL)animating sender:(NSString *)sender additionalActivationFlags:(id)flags activationHandler:(id)handler {
	if (HBLOOpenURLCoreHook(url, sender)) {
		%orig;
	}
}

%end

%group JonyIvePointOne

- (void)_openURLCore:(NSURL *)url display:(id)display animating:(BOOL)animating sender:(NSString *)sender activationContext:(id)context activationHandler:(id)handler {
	if (HBLOOpenURLCoreHook(url, sender)) {
		%orig;
	}
}

%end

%group CraigFederighi

- (void)_openURLCore:(NSURL *)url display:(id)display animating:(BOOL)animating sender:(NSString *)sender activationSettings:(id)settings withResult:(id)result {
    if (HBLOOpenURLCoreHook(url, sender)) {
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

	[HBLOHandlerController sharedInstance];

	if (IS_IOS_OR_NEWER(iOS_8_0)) {
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
