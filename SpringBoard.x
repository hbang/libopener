#import "HBLOHandlerController.h"

%ctor {
	if (!IN_SPRINGBOARD) {
		return;
	}

	[HBLOHandlerController sharedInstance];
	%init;
}
