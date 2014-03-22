#import <Preferences/PSListController.h>

@interface HBLOListController : PSViewController <UITableViewDelegate, UITableViewDataSource> {
	NSArray *_handlers;
	NSMutableDictionary *_prefs;
}

@property (nonatomic, retain) UITableView *view;

@end
