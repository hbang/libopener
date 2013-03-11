/**
 * libopener
 *
 * by HASHBANG Productions <http://hbang.ws>
 * GPL licensed <http://hbang.ws/s/gpl>
 */

#import "HBLOGlobal.h"
#import <SpringBoard/SpringBoard.h>

%group HBLOSpringBoard5
%hook SpringBoard
-(void)_openURLCore:(NSURL *)url display:(id)display publicURLsOnly:(BOOL)publicOnly animating:(BOOL)animating additionalActivationFlag:(unsigned int)flags {
	if (!HBLOShouldOverrideOpenURL(url)) {
		%orig;
	}
}
%end
%end

%group HBLOSpringBoard6
%hook SpringBoard
-(void)_openURLCore:(NSURL *)url display:(id)display animating:(BOOL)animating sender:(id)sender additionalActivationFlags:(id)flags {
	if (!HBLOShouldOverrideOpenURL(url)) {
		%orig;
	}
}
%end
%end

%ctor {
	if (IN_SPRINGBOARD) {
		if ([%c(SpringBoard) instancesRespondToSelector:@selector(_openURLCore:display:animating:sender:additionalActivationFlags:)]) {
			%init(HBLOSpringBoard6);
		} else {
			%init(HBLOSpringBoard5);
		}
	}
}
