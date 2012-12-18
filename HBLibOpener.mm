/**
 * libopener
 *
 * by HASHBANG Productions <http://hbang.ws>
 * GPL licensed <http://hbang.ws/s/gpl>
 */

#import "HBLibOpener.h"

@implementation HBLibOpener
static HBLibOpener *sharedInstance;
static NSMutableArray *_registeredNames;
static NSMutableArray *_handlers;
-(id)init {
	self = [super init];
	if (self) {
		sharedInstance = self;
		_registeredNames = [[NSMutableArray alloc] init];
		_handlers = [[NSMutableArray alloc] init];
	}
	return self;
}
+(HBLibOpener *)sharedInstance {
	if (!sharedInstance) {
		sharedInstance = [[[self alloc] init] autorelease];
	}
	return sharedInstance;
}
-(BOOL)registerHandlerWithName:(NSString *)name block:(NSURL *(^)(NSURL *url))block {
	if ([_registeredNames containsObject:name]) {
		return NO;
	}

	[_registeredNames addObject:name];
	[_handlers addObject:[block copy]];

	return YES;
}
-(NSMutableArray *)handlers {
	return _handlers;
}
@end
