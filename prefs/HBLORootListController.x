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

	HBLOHandlerController *handlerController = [%c(HBLOHandlerController) sharedInstance];
	[handlerController loadHandlers];

	_handlers = [handlerController.handlers copy];

	NSMutableArray *newSpecifiers = [NSMutableArray array];

	for (HBLOHandler *handler in _handlers) {
		BOOL isLink = YES;//handler.preferencesBundle && handler.preferencesClass;

		PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:handler.name target:self set:@selector(setPreferenceValue:specifier:) get:@selector(readPreferenceValue:) detail:Nil cell:isLink ? PSLinkCell : PSSwitchCell edit:Nil];

		if (isLink) {
			specifier.properties = [@{
				PSDefaultValueKey: @YES,
				PSDefaultsKey: @"ws.hbang.libopener",
				PSKeyNameKey: handler.identifier,
				PSValueChangedNotificationKey: @"ws.hbang.libopener/ReloadPrefs"
			} mutableCopy];
		} else {
			specifier.properties = [@{
				PSBundlePathKey: handler.preferencesBundle.bundlePath,
				PSDetailControllerClassKey: handler.preferencesClass
			} mutableCopy];
		}

		[newSpecifiers addObject:specifier];
	}

	if (newSpecifiers.count > 0) {
		[self insertContiguousSpecifiers:newSpecifiers afterSpecifierID:@"HandlersGroupCell"];
		[self removeSpecifierID:@"HandlersNoneInstalledGroupCell"];
	} else {
		[self removeSpecifierID:@"HandlersGroupCell"];
	}
}

#pragma mark - Memory management

- (void)dealloc {
	[_handlers release];

	[super dealloc];
}

@end
