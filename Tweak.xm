/**
 * libopener
 *
 * by HASHBANG Productions <http://hbang.ws>
 * GPL licensed <http://hbang.ws/s/gpl>
 */

#import "HBLibOpener.h"

@interface HBLibOpener (Private)
-(NSMutableArray *)handlers;
@end

@interface SpringBoard : UIApplication
-(void)applicationOpenURL:(NSURL *)url publicURLsOnly:(BOOL)publicOnly;
@end

static BOOL isHookedValue = NO;

%hook SpringBoard
-(void)_openURLCore:(NSURL *)url display:(id)display publicURLsOnly:(BOOL)publicOnly animating:(BOOL)animating additionalActivationFlag:(unsigned int)flags {
	if (isHookedValue) {
		%orig;
		isHookedValue = NO;
		return;
	}

	for (NSURL *(^block)(NSURL *) in [HBLibOpener sharedInstance].handlers) {
		NSURL *newUrl = block(url);
		if (newUrl) {
			isHookedValue = YES;
			[(SpringBoard *)[%c(SpringBoard) sharedApplication] applicationOpenURL:newUrl publicURLsOnly:NO];
			return;
		}
	}

	%orig;
}
-(void)_openURLCore:(NSURL *)url display:(id)display animating:(BOOL)animating sender:(id)sender additionalActivationFlags:(id)flags {
	if (isHookedValue) {
		%orig;
		isHookedValue = NO;
		return;
	}

	for (NSURL *(^block)(NSURL *) in [HBLibOpener sharedInstance].handlers) {
		NSURL *newUrl = block(url);
		if (newUrl) {
			isHookedValue = YES;
			[(SpringBoard *)[%c(SpringBoard) sharedApplication] applicationOpenURL:newUrl publicURLsOnly:NO];
			return;
		}
	}

	%orig;
}
%end

%ctor {
	%init;
	[HBLibOpener sharedInstance];
}
