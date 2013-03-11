/**
 * libopener
 *
 * by HASHBANG Productions <http://hbang.ws>
 * GPL licensed <http://hbang.ws/s/gpl>
 */

#import "HBLibOpener.h"
#import "HBLOGlobal.h"
#import <AppSupport/CPDistributedMessagingCenter.h>
#include <notify.h>

@implementation HBLibOpener

@synthesize handlers = _handlers, enabledHandlers = _enabledHandlers;

static HBLibOpener *sharedInstance;

-(id)init {
	if (sharedInstance) {
		return nil;
	}

	self = [super init];

	if (self) {
		sharedInstance = self;
		_handlers = [[NSMutableDictionary alloc] init];
		_enabledHandlers = [[NSArray alloc] init];

		if (IN_SPRINGBOARD) {
			CPDistributedMessagingCenter *messagingServer = [CPDistributedMessagingCenter centerNamed:@"ws.hbang.libopener.server"];
			[messagingServer runServerOnCurrentThread];
			[messagingServer registerForMessageName:@"GetHandlers" target:self selector:@selector(_receivedMessage:)];
		}
	}

	return self;
}

-(void)dealloc {
	[_handlers release];
	[_enabledHandlers release];
	[super dealloc];
}

#pragma mark Public API

+(HBLibOpener *)sharedInstance {
	if (!sharedInstance) {
		[[self alloc] init];
	}

	return sharedInstance;
}

-(BOOL)registerHandlerWithName:(NSString *)name block:(NSURL *(^)(NSURL *url))block {
	if (!IN_SPRINGBOARD || [_handlers objectForKey:name]) {
		return NO;
	}

	[_handlers setObject:[block copy] forKey:name];
	[self _preferencesUpdated];

	return YES;
}

-(BOOL)handlerIsEnabled:(NSString *)handler {
	return !![_enabledHandlers containsObject:handler];
}

#pragma mark Private API

-(void)_preferencesUpdated {
	NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:PREFS_PATH];
	NSMutableArray *newHandlers = [NSMutableArray array];

	for (NSString *handler in _handlers.allKeys) {
		if (![prefs objectForKey:handler] || [[prefs objectForKey:handler] boolValue]) {
			[newHandlers addObject:handler];
		}
	}

	_enabledHandlers = [newHandlers copy];

	//notify_post("ws.hbang.libopener/ReloadPrefsApp"); // to be continued some other day...
}

-(id)_receivedMessage:(NSString *)message {
	return [NSDictionary dictionaryWithObject:_handlers.allKeys forKey:@"Handlers"];
}

@end
