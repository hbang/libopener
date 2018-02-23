@class HBLOHandler, HBLOOpenOperation, LSApplicationProxy;

@interface HBLOHandlerController : NSObject

+ (instancetype)sharedInstance;

- (BOOL)registerHandler:(HBLOHandler *)handler error:(NSError **)error;
- (void)loadHandlers;

- (NSString *)foregroundBundleIdentifier;

- (NSArray <HBLOOpenOperation *> *)getReplacementsForOpenOperation:(HBLOOpenOperation *)openOperation;

@property (nonatomic, retain) NSMutableArray *handlers;

@end
