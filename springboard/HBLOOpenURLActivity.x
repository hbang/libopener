#import "HBLOOpenURLActivity.h"
#import <MobileCoreServices/LSApplicationProxy.h>
#import <MobileCoreServices/LSApplicationWorkspace.h>
#import <MobileCoreServices/LSOpenOperation.h>
#import <UIKit/UIActivity+Private.h>
#import <UIKit/UIImage+Private.h>

@implementation HBLOOpenURLActivity {
	NSURL *_url;
	NSString *_bundleIdentifier;
	LSApplicationProxy *_applicationProxy;
	NSDictionary *_openOperationOptions;
}

+ (NSString *)nameForCategory:(HBLOActivityCategory)category {
	switch (category) {
		case HBLOActivityCategoryBrowser:
			return @"Browsers";
			break;

		case HBLOActivityCategoryApp:
			return @"Applications";
			break;
	}
}

+ (UIActivityCategory)activityCategory {
	return (UIActivityCategory)HBLOActivityCategoryApp;
}

- (instancetype)initWithURL:(NSURL *)url bundleIdentifier:(NSString *)bundleIdentifier openOperationOptions:(NSDictionary *)openOperationOptions {
	self = [self init];

	if (self) {
		_url = [url copy];
		_bundleIdentifier = [bundleIdentifier copy];
		_applicationProxy = [[LSApplicationProxy applicationProxyForIdentifier:bundleIdentifier] retain];
		_openOperationOptions = [openOperationOptions copy];
	}

	return self;
}

- (NSString *)activityType {
	return [@"ws.hbang.libopener.activity-" stringByAppendingString:_bundleIdentifier];
}

- (NSString *)activityTitle {
	return _applicationProxy.localizedName;
}

- (UIImage *)_activityImage {
	return [UIImage _iconForResourceProxy:_applicationProxy format:12];
}

- (UIImage *)_activitySettingsImage {
	return [UIImage _iconForResourceProxy:_applicationProxy format:0];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
	if (!_applicationProxy.isInstalled) {
		return NO;
	}

	for (id item in activityItems) {
		if ([item isKindOfClass:NSURL.class]) {
			NSArray *apps = [[LSApplicationWorkspace defaultWorkspace] applicationsAvailableForHandlingURLScheme:((NSURL *)item).scheme];

			if (apps.count > 0) {
				return YES;
			}
		}
	}

	return NO;
}

- (void)performActivity {
	// LSOpenOperation *openOperation = [[[%c(LSOpenOperation) alloc] initForOpeningResource:_url usingApplication:_bundleIdentifier uniqueDocumentIdentifier:nil sourceIsManaged:NO userInfo:nil options:_openOperationOptions delegate:nil] autorelease];
	// [openOperation main];
	// [self activityDidFinish:openOperation.didSucceed];
	[self activityDidFinish:NO];
}

#pragma mark - Memory management

- (void)dealloc {
	[_url release];
	[_bundleIdentifier release];
	[_applicationProxy release];
	[_openOperationOptions release];

	[super dealloc];
}

@end
