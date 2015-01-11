#import "HBLOGlobal.h"
#import "HBLOListController.h"
#import "HBLOAboutListController.h"
#import "../HBLOHandler.h"
#import "../HBLOHandlerController.h"
#import <AppSupport/CPDistributedMessagingCenter.h>
#import <Preferences/PSSpecifier.h>
#import <CepheiPrefs/HBTwitterCell.h>
#include <notify.h>

@implementation HBLOListController {
    NSArray *_handlers;
    NSMutableDictionary *_prefs;
}

#pragma mark - UIViewController

- (void)loadView {
	[super loadView];

	self.view = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStyleGrouped];
	self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	self.view.delegate = self;
	self.view.dataSource = self;

	_prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:kHBLOPreferencesPath] ?: [[NSMutableDictionary alloc] init];

    // we can't get these within the app since it won't include legacy handlers.
    NSDictionary *callback = [[CPDistributedMessagingCenter centerNamed:kHBLOMessagingCenterName] sendMessageAndReceiveReplyName:kHBLOGetHandlersMessage userInfo:nil];
    _handlers = [callback[kHBLOHandlersKey] copy];
}

#pragma mark - PSViewController

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
	return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	switch (section) {
		case 1:
			return _handlers.count;
			break;

		case 2:
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
            NSDictionary *handler = _handlers[indexPath.row];

			if (handler[kHBLOHandlerPreferencesClassKey] && ![handler[kHBLOHandlerPreferencesClassKey] isEqualToString:@""]) {
				static NSString *ReuseIdentifier = @"LibOpenerControllerCell";

				cell = [tableView dequeueReusableCellWithIdentifier:ReuseIdentifier];

				if (!cell) {
					cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ReuseIdentifier] autorelease];
					cell.selectionStyle = UITableViewCellSelectionStyleBlue;
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				}
			} else {
				static NSString *ReuseIdentifier = @"LibOpenerSwitchCell";

				cell = [tableView dequeueReusableCellWithIdentifier:ReuseIdentifier];

				if (!cell) {
					cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ReuseIdentifier] autorelease];
					cell.selectionStyle = UITableViewCellSelectionStyleNone;

					cell.accessoryView = [[UISwitch alloc] init];
					[(UISwitch *)cell.accessoryView addTarget:self action:@selector(didToggleSwitch:) forControlEvents:UIControlEventValueChanged];
				}

                cell.accessoryView.tag = indexPath.row;
				((UISwitch *)cell.accessoryView).on = _prefs[handler[kHBLOHandlerIdentifierKey]] ? ((NSNumber *)_prefs[handler[kHBLOHandlerIdentifierKey]]).boolValue : YES;
			}

			cell.textLabel.text = handler[kHBLOHandlerNameKey];

			return cell;
			break;
		}

		case 2:
		{
			static NSString *ReuseIdentifier = @"LibOpenerAboutCell";

			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ReuseIdentifier];

			if (!cell) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ReuseIdentifier] autorelease];
                cell.textLabel.text = @"About";
                cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
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

		default:
			return nil;
			break;
	}
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    PSViewController *controller = nil;

    switch (indexPath.section) {
        case 1:
        {
            NSString *class = _handlers[indexPath.row][kHBLOHandlerPreferencesClassKey];

            if (class && ![class isEqualToString:@""]) {
                controller = [[[NSClassFromString(class) alloc] init] autorelease];
            }

            break;
        }

        case 2:
        {
            controller = [[[HBLOAboutListController alloc] init] autorelease];
            break;
        }
    }

    if (controller) {
        [self pushController:controller];
    }
}

#pragma mark - Callback methods

- (void)didToggleSwitch:(UISwitch *)sender {
	_prefs[_handlers[sender.tag][kHBLOHandlerIdentifierKey]] = @(sender.on);
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
