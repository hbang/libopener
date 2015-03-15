#import "HBLOActivity.h"

@implementation HBLOActivity {
	NSURL *_url;
	NSString *_bundleIdentifier;
	NSString *_localizedName;
	NSDictionary *_openOperationOptions;
}

+ (NSString *)nameForCategory:(HBLOActivityCategory)category {
	switch (category) {
		case HBLOActivityCategoryBrowser:
			return @"Browsers";
			break;

		case HBLOActivityCategoryApps:
			return @"Applications";
			break;
	}
}

+ (UIActivityCategory)activityCategory {
	return UIActivityCategoryShare;
}

- (instancetype)initWithURL:(NSURL *)url bundleIdentifier:(NSString *)bundleIdentifier openOperationOptions:(NSDictionary *)openOperationOptions {
	self = [self init];

	if (self) {
		_url = [url copy];
		_bundleIdentifier = [bundleIdentifier copy];
		_localizedName = [[LSApplicationProxy applicationProxyForIdentifier:_bundleIdentifier].localizedName copy];
		_openOperationOptions = [openOperationOptions copy];
	}

	return self;
}

- (NSString *)activityType {
	return [@"ws.hbang.libopener.activity-" stringByAppendingString:_bundleIdentifier];
}

- (NSString *)activityTitle {
	return _localizedName;
}

- (UIImage *)activityImage {
	return [self.class _activityImageForApplication:_bundleIdentifier];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
	return YES;
}

- (void)performActivity {
	LSOpenOperation *openOperation = [[[LSOpenOperation alloc] initForOpeningResource:_url usingApplication:_bundleIdentifier uniqueDocumentIdentifier:nil sourceIsManaged:NO userInfo:nil options:_openOperationOptions delegate:nil] autorelease];
	[openOperation main];
	[self activityDidFinish:openOperation.didSucceed];
}

#pragma mark - Memory management

- (void)dealloc {
	[_url release];
	[_bundleIdentifier release];
	[_localizedName release];
	[_openOperationOptions release];

	[super dealloc];
}

@end
