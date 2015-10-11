typedef void (^HBLOHandlerChooserViewControllerCompletionHandler)(NSString *activityType, BOOL completed);

@interface HBLOHandlerChooserViewController : UIActivityViewController

- (instancetype)initWithURL:(NSURL *)url openOperationOptions:(NSDictionary *)openOperationOptions;

@property (nonatomic, copy) HBLOHandlerChooserViewControllerCompletionHandler completionHandler;

@end
