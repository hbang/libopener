typedef NS_ENUM(NSUInteger, HBLOActivityCategory) {
	HBLOActivityCategoryBrowser,
	HBLOActivityCategoryApp
};

@interface HBLOActivity : UIActivity

+ (NSString *)nameForCategory:(HBLOActivityCategory)category;

- (instancetype)initWithURL:(NSURL *)url bundleIdentifier:(NSString *)bundleIdentifier openOperationOptions:(NSDictionary *)openOperationOptions;

@property HBLOActivityCategory category;
@property (nonatomic, retain, readonly) NSURL *activityURL;

@end
