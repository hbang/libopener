#import "HBLOGlobal.h"
#import "HBLOListController.h"
#import "HBLOFooterCell.h"
#import "../HBLOHandler.h"
#import "../HBLOHandlerController.h"
#import <AppSupport/CPDistributedMessagingCenter.h>
#import <Preferences/PSSpecifier.h>
#import <libhbangcommon/HBTwitterCell.h>
#include <notify.h>

@implementation HBLOListController {
    NSArray *_handlers;
    NSMutableDictionary *_prefs;
}

#pragma mark - PSViewController

- (void)loadView {
	[super loadView];

	self.view = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStyleGrouped];
	self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	self.view.delegate = self;
	self.view.dataSource = self;

	_prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:kHBLOPreferencesPath] ?: [[NSMutableDictionary alloc] init];
    _handlers = [[HBLOHandlerController sharedInstance].handlers sortedArrayUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES] ]];
}

- (void)setSpecifier:(PSSpecifier *)specifier {
	[super setSpecifier:specifier];
	self.title = specifier.name;
}

- (CGSize)contentSize {
	return self.view.frame.size;
}

- (UITableView *)table {
	return self.view;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	switch (section) {
		case 1:
			return _handlers.count;
			break;

		case 3:
			return 1;
			break;

		default:
			return 0;
			break;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	switch (indexPath.section) {
		case 1:
		{
			UITableViewCell *cell = nil;
            HBLOHandler *handler = _handlers[indexPath.row];

			if (handler.preferencesClass) {
				static NSString *ReuseIdentifier = @"LibOpenerControllerCell";

				UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ReuseIdentifier];

				if (!cell) {
					cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ReuseIdentifier] autorelease];
					cell.selectionStyle = UITableViewCellSelectionStyleBlue;
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				}
			} else {
				static NSString *ReuseIdentifier = @"LibOpenerSwitchCell";

				UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ReuseIdentifier];

				if (!cell) {
					cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ReuseIdentifier] autorelease];
					cell.selectionStyle = UITableViewCellSelectionStyleNone;

					cell.accessoryView = [[UISwitch alloc] init];
					cell.accessoryView.tag = indexPath.row;
					[(UISwitch *)cell.accessoryView addTarget:self action:@selector(didToggleSwitch:) forControlEvents:UIControlEventValueChanged];
				}

				((UISwitch *)cell.accessoryView).on = _prefs[handler.identifier] ? ((NSNumber *)_prefs[handler.identifier]).boolValue : YES;

				return cell;
			}

			cell.textLabel.text = handler.name;

			return cell;
			break;
		}

		case 3:
		{
			static NSString *ReuseIdentifier = @"LibOpenerFooterCell";

			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ReuseIdentifier];

			if (!cell) {
				PSSpecifier *specifier = [[[PSSpecifier alloc] init] autorelease];
				specifier.name = @"HASHBANG Productions";
				specifier.properties = @{
					@"user": @"hbangws"
				};

				cell = [[[HBTwitterCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ReuseIdentifier specifier:specifier] autorelease];
			}

			return cell;
			break;
		}

		default:
		{
			return nil;
			break;
		}
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	switch (section) {
		case 0:
			return _handlers.count == 0 ? nil : @"Handlers";
			break;

		case 2:
			return @"About";
			break;

		default:
			return nil;
			break;
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	switch (section) {
		case 0:
			return _handlers.count == 0 ? @"Opener is a developer library for overriding link destinations - for example, to redirect opening a YouTube link in Safari to a 3rd-party YouTube app.\n\nYou currently don’t have any handler packages installed. This can happen after uninstalling all packages that depend on Opener, such as MapsOpener and YTOpener. To remove this Settings page, search for “Opener” in Cydia, then tap Modify and Remove.\n" : @"Turn off handlers below to prevent them from overriding URLs.";
			break;

		case 2:
			return @"Opener Version 1.1.2\nBy HASHBANG Productions";
			break;

		default:
			return nil;
			break;
	}
}

#pragma mark - Callback methods

- (void)didToggleSwitch:(UISwitch *)sender {
	_prefs[_handlers[sender.tag]] = @(sender.on);
	[_prefs writeToFile:kHBLOPreferencesPath atomically:YES];

	notify_post("ws.hbang.libopener/ReloadPrefs");
}

#pragma mark - Memory management

- (void)dealloc {
	[_prefs release];
	[_handlers release];

	[super dealloc];
}

@end
