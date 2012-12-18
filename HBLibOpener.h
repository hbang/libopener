/**
 * libopener
 *
 * by HASHBANG Productions <http://hbang.ws>
 * GPL licensed <http://hbang.ws/s/gpl>
 */

@interface HBLibOpener : NSObject
+(HBLibOpener *)sharedInstance;
-(BOOL)registerHandlerWithName:(NSString *)name block:(NSURL *(^)(NSURL *url))block;
@end
