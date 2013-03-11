/**
 * libopener
 *
 * by HASHBANG Productions <http://hbang.ws>
 * GPL licensed <http://hbang.ws/s/gpl>
 */

@interface HBLibOpener : NSObject {
	NSMutableDictionary *_handlers;
	NSArray *_enabledHandlers;
}

+(HBLibOpener *)sharedInstance;
-(BOOL)registerHandlerWithName:(NSString *)name block:(NSURL *(^)(NSURL *url))block;
-(BOOL)handlerIsEnabled:(NSString *)handler;

@property (nonatomic, retain, readonly) NSMutableDictionary *handlers;
@property (nonatomic, retain, readonly) NSArray *enabledHandlers;
@end
