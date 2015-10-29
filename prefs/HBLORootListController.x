#import "HBLORootListController.h"
#import "../HBLOHandler.h"
#import "../HBLOHandlerController.h"
#import <AppSupport/CPDistributedMessagingCenter.h>
#import <Preferences/PSSpecifier.h>
#include <notify.h>

static NSString *const LOBundleKey = @"libopener_bundle";
static NSString *const LOBundleClassKey = @"libopener_bundleClass";

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
				LOBundleKey: handler.preferencesBundle,
				LOBundleClassKey: handler.preferencesClass
				PSActionKey: @"showPreferencesForSpecifier:"
			} mutableCopy];
		} else {
			specifier.properties = [@{
				PSDefaultValueKey: @YES,
				PSDefaultsKey: @"ws.hbang.libopener",
				PSKeyNameKey: handler.identifier,
				PSValueChangedNotificationKey: @"ws.hbang.libopener/ReloadPrefs"
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

#pragma mark - Callbacks

- (void)showPreferencesForSpecifier:(PSSpecifier *)specifier {
	NSBundle *bundle = specifier.properties[LOBundleKey];
	[bundle load];

	Class principalClass = NSClassFromString(specifier.properties[LOBundleClassKey]);
	BOOL failed = NO;

	if (!principalClass) {
		principalClass = bundle.principalClass;

		if (!principalClass) {
			failed = YES;
		}
	}

	PSListController *controller = [[[principalClass alloc] init] autorelease];

	if (!controller) {
		failed = YES;
	}

	if (failed) {
		NSBundle *openerBundle = [NSBundle bundleForClass:self.class];
		NSBundle *uikitBundle = [NSBundle bundleForClass:UIView.class];

		UIAlertView *alertView = [[[UIAlertView alloc] init] autorelease];
		alertView.title = NSLocalizedStringFromTableInBundle(@"BUNDLE_LOAD_FAILED_TITLE", @"Root", openerBundle, @"Title displayed when a handler’s settings fails to load.");
		alertView.message = NSLocalizedStringFromTableInBundle(@"BUNDLE_LOAD_FAILED_BODY", @"Root", openerBundle, @"Message body displayed when a handler’s settings fails to load.");
		[alertView addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"OK", @"Localizable", uikitBundle, @"OK")];
		[alertView show];
	} else {
		[self pushController:controller];
	}
}

#pragma mark - Memory management

- (void)dealloc {
	[_handlers release];

	[super dealloc];
}

@end
