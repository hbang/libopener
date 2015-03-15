@class HBLOHandler;

@interface HBLOHandlerController : NSObject

+ (instancetype)sharedInstance;

- (BOOL)registerHandler:(HBLOHandler *)handler error:(NSError **)error;
- (void)loadHandlers;

- (BOOL)openURL:(NSURL *)url sender:(NSString *)sender;
- (NSArray *)getReplacementsForURL:(NSURL *)url sender:(NSString *)sender;

- (BOOL)handlerIsEnabled:(HBLOHandler *)handler;
- (BOOL)handlerIdentifierIsEnabled:(NSString *)identifier;

@property (nonatomic, retain) NSMutableArray *handlers;

@end
