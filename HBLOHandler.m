#import "HBLOHandler.h"

@implementation HBLOHandler

- (NSURL *)openURL:(NSURL *)url sender:(NSString *)sender {
	[NSException raise:NSInternalInconsistencyException format:@"Handler %@ did not override openURL:sender:, or called the superclass implementation.", self.class];
	return nil;
}

#pragma mark - NSObject

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p; name = %@; id = %@; prefs = %@ - %@>", self.class, self, self.name, self.identifier, self.preferencesBundle, self.preferencesClass];
}

@end
