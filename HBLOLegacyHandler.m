#import "HBLOLegacyHandler.h"

@implementation HBLOLegacyHandler

#pragma mark - HBLOHandler

- (NSURL *)openURL:(NSURL *)url sender:(NSString *)sender {
	return _legacyBlock(url);
}

#pragma mark - Memory management

- (void)dealloc {
	[_legacyBlock release];
	[super dealloc];
}

@end
