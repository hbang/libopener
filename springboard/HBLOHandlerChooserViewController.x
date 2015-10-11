#import "HBLOHandlerChooserViewController.h"
#import "HBLOOpenBrowserActivity.h"
#import "HBLOOpenURLActivity.h"
#import <UIKit/UIActivityViewController+Private.h>
#import <version.h>

@implementation HBLOHandlerChooserViewController {
	NSDictionary *_openOperationOptions;
}

@dynamic completionHandler;

- (instancetype)initWithURL:(NSURL *)url openOperationOptions:(NSDictionary *)openOperationOptions {
	self = [super initWithActivityItems:@[ url ] applicationActivities:nil];

	if (self) {
		_openOperationOptions = [openOperationOptions copy];
	}

	return self;
}

- (NSArray *)_availableActivitiesForItems:(NSArray *)items applicationExtensionActivities:(NSArray *)applicationExtensionActivities {
	if (items.count != 1 || ![items[0] isKindOfClass:NSURL.class]) {
		return nil;
	}

	NSMutableArray *activities = [[[super _availableActivitiesForItems:items applicationExtensionActivities:applicationExtensionActivities] autorelease] mutableCopy];
	[activities addObject:[[HBLOOpenBrowserActivity alloc] initWithURL:items[0] bundleIdentifier:@"com.google.chrome.ios" openOperationOptions:_openOperationOptions]];
	return activities;
}

#pragma mark - Memory management

- (void)dealloc {
	[_openOperationOptions release];

	[super dealloc];
}

@end
