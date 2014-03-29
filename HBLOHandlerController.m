#import "HBLOGlobal.h"
#import "HBLOHandlerController.h"
#import "HBLOHandler.h"
#import <SpringBoard/SpringBoard.h>
#import <SpringBoardServices/SpringBoardServices.h>

@implementation HBLOHandlerController {
	NSDictionary *_preferences;
	BOOL _hasLoadedHandlers;
}

+ (instancetype)sharedInstance {
	static HBLOHandlerController *sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[self alloc] init];
	});

	return sharedInstance;
}

- (instancetype)init {
	self = [super init];

	if (self) {
		_handlers = [[NSMutableArray alloc] init];

		[self preferencesUpdated];
	}

	return self;
}

#pragma mark - Registration/loading

- (BOOL)registerHandler:(HBLOHandler *)handler error:(NSError **)error {
	for (HBLOHandler *handler2 in _handlers) {
		if ([handler.identifier isEqualToString:handler2.identifier]) {
			*error = [NSError errorWithDomain:HBLOErrorDomain code:1 userInfo:@{
				NSLocalizedDescriptionKey: [NSString stringWithFormat:@"The handler \"%@\" is already registered.", handler.identifier]
			}];

			return NO;
		}
	}

	[_handlers addObject:handler];
	return YES;
}

- (void)loadHandlers {
	if (_hasLoadedHandlers) {
		NSLog(@"libopener: you only load handlers once (YOLHO)");
		return;
	}

	NSLog(@"libopener: loading handlers");

	_hasLoadedHandlers = YES;

	NSURL *handlersURL = [NSURL URLWithString:kHBLOHandlersURL];

	NSError *error = nil;
	NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:handlersURL includingPropertiesForKeys:nil options:kNilOptions error:&error];

	if (error) {
		NSLog(@"libopener: failed to access handler directory %@: %@", kHBLOHandlersURL, error.localizedDescription);
		return;
	}

	NSMutableArray *handlers = [NSMutableArray array];

	for (NSString *directory in contents) {
		NSLog(@"libopener: loading %@", directory);

		NSBundle *bundle = [NSBundle bundleWithURL:[handlersURL URLByAppendingPathComponent:directory]];

		if (!bundle) {
			NSLog(@"libopener: failed to load bundle for handler %@", directory);
			return;
		}

		[bundle load];

		if (!bundle.principalClass) {
			NSLog(@"libopener: no principal class for handler %@", directory);
			return;
		}

		HBLOHandler *handler = [[[bundle.principalClass alloc] init] autorelease];

		if (!handler) {
			NSLog(@"libopener: failed to initialise principal class for %@", directory);
			return;
		}

		NSError *error = nil;

		if (![self registerHandler:handler error:&error]) {
			NSLog(@"libopener: error registering handler %@: %@", directory, error.localizedDescription);
		}
	}

	if (_handlers) {
		[_handlers release];
	}

	_handlers = [handlers copy];
}

#pragma mark - Open URL

- (BOOL)openURL:(NSURL *)url sender:(NSString *)sender {
	if (!_hasLoadedHandlers) {
		[self loadHandlers];
	}

	for (HBLOHandler *handler in _handlers) {
		if (![self handlerIsEnabled:handler]) {
			continue;
		}

		NSURL *newUrl = [handler openURL:url sender:sender];

		if (newUrl) {
			if (IN_SPRINGBOARD) {
				[(SpringBoard *)[UIApplication sharedApplication] applicationOpenURL:newUrl publicURLsOnly:NO];
			} else {
				SBSOpenSensitiveURLAndUnlock((CFURLRef)newUrl, 1);
			}

			return YES;
		}
	}

	return NO;
}

#pragma mark - Preferences

- (void)preferencesUpdated {
	[_preferences release];
	_preferences = [[NSDictionary alloc] initWithContentsOfFile:kHBLOPreferencesPath];
}

- (BOOL)handlerIdentifierIsEnabled:(NSString *)identifier {
	return _preferences[identifier] ? ((NSNumber *)_preferences[identifier]).boolValue : YES;
}

- (BOOL)handlerIsEnabled:(HBLOHandler *)handler {
	return [self handlerIdentifierIsEnabled:handler.identifier];
}

@end
