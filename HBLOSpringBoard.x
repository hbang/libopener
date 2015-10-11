#import "HBLOGlobal.h"
#import "HBLOHandlerController.h"

%ctor {
	if (!IN_SPRINGBOARD) {
		return;
	}

	[HBLOHandlerController sharedInstance];
}
