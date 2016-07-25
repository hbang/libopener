@class HBLOHandler;

@interface HBLOPreferences : NSObject

+ (instancetype)sharedInstance;

- (BOOL)isHandlerEnabled:(HBLOHandler *)handler;
- (BOOL)isHandlerIdentifierEnabled:(NSString *)identifier;

@property (nonatomic) BOOL inDebugMode;

@end
