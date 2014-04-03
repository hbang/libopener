#import "HBLOAboutListController.h"
#import <Preferences/PSSpecifier.h>

@implementation HBLOAboutListController

- (instancetype)init {
	self = [super init];

	if (self) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"About" target:self] retain];
	}

	return self;
}

@end
