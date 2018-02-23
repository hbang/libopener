@class LSApplicationProxy, LSAppLink;

NS_ASSUME_NONNULL_BEGIN

@interface HBLOOpenOperation : NSObject <NSCoding, NSSecureCoding>

@property (nonatomic, strong, getter=URL, setter=setURL:) NSURL *url;
@property (nonatomic, strong, nullable) LSApplicationProxy *application;

+ (instancetype)openOperationWithURL:(NSURL *)url application:(nullable LSApplicationProxy *)application;
+ (instancetype)openOperationWithURL:(NSURL *)url sender:(nullable NSString *)bundleIdentifier;

@end

NS_ASSUME_NONNULL_END
