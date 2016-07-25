@class HBLOHandler, LSApplicationProxy;

@interface HBLOHandlerController : NSObject

+ (instancetype)sharedInstance;

- (BOOL)registerHandler:(HBLOHandler *)handler error:(NSError **)error;
- (void)loadHandlers;

- (NSArray <NSURL *> *)getReplacementsForURL:(NSURL *)url application:(LSApplicationProxy *)application sender:(NSString *)sender options:(NSDictionary *)options;
- (NSArray <NSURL *> *)getReplacementsForURL:(NSURL *)url sender:(NSString *)sender;

@property (nonatomic, retain) NSMutableArray *handlers;

@end
