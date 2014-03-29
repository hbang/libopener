#import "HBLOHandlerController.h"

%hook UIWebDocumentView

- (void)loadRequest:(NSURLRequest *)request {
    if (![[HBLOHandlerController sharedInstance] openURL:request.URL sender:[NSBundle mainBundle].bundleIdentifier]) {
        %orig;
    }
}

%end
