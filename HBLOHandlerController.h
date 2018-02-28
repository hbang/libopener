@class HBLOHandler, HBLOOpenOperation, LSApplicationProxy;

@interface HBLOHandlerController : NSObject

+ (NSString *)foregroundBundleIdentifier;

+ (instancetype)sharedInstance;

- (BOOL)registerHandler:(HBLOHandler *)handler error:(NSError **)error;
- (void)loadHandlers;

- (NSArray <HBLOOpenOperation *> *)getReplacementsForOpenOperation:(HBLOOpenOperation *)openOperation;

@property (nonatomic, retain) NSMutableArray <HBLOHandler *> *handlers;

@end
