#import "HBLOOpenOperation.h"
#import <MobileCoreServices/LSApplicationProxy.h>

@implementation HBLOOpenOperation

#pragma mark - Conveniences

+ (instancetype)openOperationWithURL:(NSURL *)url application:(LSApplicationProxy *)application {
	HBLOOpenOperation *openOperation = [[HBLOOpenOperation alloc] init];
	openOperation.URL = url;
	openOperation.application = application;
	return openOperation;
}

+ (instancetype)openOperationWithURL:(NSURL *)url sender:(NSString *)bundleIdentifier {
	return [self openOperationWithURL:url application:bundleIdentifier ? [LSApplicationProxy applicationProxyForIdentifier:bundleIdentifier] : nil];
}

#pragma mark - NSObject

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p; url = %@; application = %@>", self.class, self, _url, _application.applicationIdentifier];
}

#pragma mark - NSCoding

+ (BOOL)supportsSecureCoding {
	return YES;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
	self = [self init];

	if (self) {
		_url = [coder decodeObjectOfClass:NSURL.class forKey:@"url"];

		NSString *bundleIdentifier = [coder decodeObjectOfClass:NSString.class forKey:@"bundleIdentifier"];
		_application = bundleIdentifier ? [LSApplicationProxy applicationProxyForIdentifier:bundleIdentifier] : nil;
	}

	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:_url forKey:@"url"];

	if (_application) {
		[coder encodeObject:_application.applicationIdentifier forKey:@"bundleIdentifier"];
	}
}

@end
