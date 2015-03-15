@interface HBLOHandlerChooserController : NSObject

+ (instancetype)sharedInstance;

- (BOOL)openURL:(NSURL *)url options:(NSDictionary *)options;
- (void)presentChooserForURL:(NSURL *)url options:(NSDictionary *)options;

@end
