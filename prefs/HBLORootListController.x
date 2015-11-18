#import "HBLORootListController.h"
#import "../HBLOHandler.h"
#import "../HBLOHandlerController.h"
#import <AppSupport/CPDistributedMessagingCenter.h>
#import <Preferences/PSSpecifier.h>
#import <UIKit/UIImage+Private.h>
#include <notify.h>

@implementation HBLORootListController {
	NSArray <HBLOHandler *> *_handlers;
}

+ (NSString *)hb_specifierPlist {
	return @"Root";
}

+ (UIColor *)hb_tintColor {
	return [UIColor colorWithRed:52.f / 255.f green:170.f / 255.f blue:220.f / 255.f alpha:1];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	[self _updateHandlers];
}

- (void)reloadSpecifiers {
	[super reloadSpecifiers];
	[self _updateHandlers];
}

#pragma mark - Update state

- (void)_updateHandlers {
	HBLOHandlerController *handlerController = [%c(HBLOHandlerController) sharedInstance];
	[handlerController loadHandlers];

	_handlers = [handlerController.handlers copy];

	NSMutableArray *newSpecifiers = [NSMutableArray array];

	for (HBLOHandler *handler in _handlers) {
		BOOL isLink = handler.preferencesBundle && handler.preferencesClass;

		PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:handler.name target:self set:@selector(setPreferenceValue:specifier:) get:@selector(readPreferenceValue:) detail:Nil cell:isLink ? PSLinkCell : PSSwitchCell edit:Nil];

		if (isLink) {
			specifier.properties = [@{
				PSIDKey: handler.identifier,
				PSBundleIsControllerKey: @YES,
				PSLazilyLoadedBundleKey: handler.preferencesBundle.bundlePath,
				PSDetailControllerClassKey: handler.preferencesClass
			} mutableCopy];

			specifier.controllerLoadAction = @selector(lazyLoadBundle:);
		} else {
			specifier.properties = [@{
				PSIDKey: handler.identifier,
				PSDefaultValueKey: @YES,
				PSDefaultsKey: @"ws.hbang.libopener",
				PSKeyNameKey: handler.identifier,
				PSValueChangedNotificationKey: @"ws.hbang.libopener/ReloadPrefs"
			} mutableCopy];
		}

		UIImage *icon = nil;
		NSBundle *iconBundle = handler.preferencesBundle ?: [NSBundle bundleForClass:handler.class];

		// if Info.plist CFBundleIconFile is set, use that
		if (iconBundle.infoDictionary[@"CFBundleIconFile"]) {
			icon = [UIImage imageNamed:iconBundle.infoDictionary[@"CFBundleIconFile"] inBundle:iconBundle];
		}

		// if that didn't work or the key doesn't exist, try icon.png
		if (!icon) {
			icon = [UIImage imageNamed:@"icon" inBundle:iconBundle];
		}

		// if we have an icon, set it on the specifier
		if (icon) {
			specifier.properties[PSIconImageKey] = [icon copy];
		} else {
			[specifier removePropertyForKey:PSIconImageKey];
		}

		[newSpecifiers addObject:specifier];
	}

	if (newSpecifiers.count > 0) {
		[self removeSpecifierID:@"HandlersNoneInstalledGroupCell"];
		[self insertContiguousSpecifiers:newSpecifiers afterSpecifierID:@"HandlersGroupCell"];
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
