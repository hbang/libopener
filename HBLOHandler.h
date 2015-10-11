#import "HBLOHandlerDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface HBLOHandler : NSObject <HBLOHandlerDelegate>

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *identifier;

@property (nonatomic, retain, nullable) NSBundle *preferencesBundle;
@property (nonatomic, retain, nullable) NSString *preferencesClass;

- (nullable id)openURL:(NSURL *)url sender:(nullable NSString *)sender;

@end

NS_ASSUME_NONNULL_END
