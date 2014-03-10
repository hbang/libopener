/**
 * libopener
 *
 * by HASHBANG Productions <http://hbang.ws>
 * GPL licensed <http://hbang.ws/s/gpl>
 */

@interface HBLibOpener : NSObject

+ (instancetype)sharedInstance;

// Allows you to register a new handler. Supported in SpringBoard only.
- (BOOL)registerHandlerWithName:(NSString *)name block:(NSURL *(^)(NSURL *url))block;

// Check whether a handler has been enabled or disabled by the user.
- (BOOL)handlerIsEnabled:(NSString *)handler;

// Dictionary of handlers and their blocks.
@property (nonatomic, retain, readonly) NSMutableDictionary *handlers;

// Array of handlers that haven't been disabled by the user.
@property (nonatomic, retain, readonly) NSArray *enabledHandlers;

@end
