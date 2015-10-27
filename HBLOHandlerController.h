@class HBLOHandler, LSApplicationProxy;

@interface HBLOHandlerController : NSObject

+ (instancetype)sharedInstance;

- (BOOL)registerHandler:(HBLOHandler *)handler error:(NSError **)error;
- (void)loadHandlers;

- (BOOL)openURL:(NSURL *)url;

- (NSArray <NSURL *> *)getReplacementsForURL:(NSURL *)url application:(LSApplicationProxy *)application sender:(NSString *)sender options:(NSDictionary *)options;
- (NSArray <NSURL *> *)getReplacementsForURL:(NSURL *)url sender:(NSString *)sender;

- (BOOL)handlerIsEnabled:(HBLOHandler *)handler;
- (BOOL)handlerIdentifierIsEnabled:(NSString *)identifier;

@property (nonatomic, retain) NSMutableArray *handlers;

@end
