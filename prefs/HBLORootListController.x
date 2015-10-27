#import "HBLORootListController.h"
#import "../HBLOHandler.h"
#import "../HBLOHandlerController.h"
#import <AppSupport/CPDistributedMessagingCenter.h>
#import <Preferences/PSSpecifier.h>
#include <notify.h>

@implementation HBLORootListController {
	NSArray <HBLOHandler *> *_handlers;
}

+ (NSString *)hb_specifierPlist {
	return @"Root";
}

#pragma mark - UIViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	_handlers = [[%c(HBLOHandlerController) sharedInstance].handlers copy];

	NSMutableArray *newSpecifiers = [NSMutableArray array];

	for (HBLOHandler *handler in _handlers) {
		BOOL isLink = handler.preferencesBundle && handler.preferencesClass;

		PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:nil target:self set:@selector(setHandlerEnabled:withSpecifier:) get:@selector(handlerEnabledWithSpecifier:) detail:Nil cell:isLink ? PSLinkCell : PSSwitchCell edit:Nil];
		[newSpecifiers addObject:specifier];
	}

	if (newSpecifiers.count > 0) {
		[self insertContiguousSpecifiers:newSpecifiers afterSpecifierID:@"HandlersGroupCell"];
		[self removeSpecifierID:@"HandlersNoneInstalledGroupCell"];
	}
}

#pragma mark - Memory management

- (void)dealloc {
	[_handlers release];

	[super dealloc];
}

@end
