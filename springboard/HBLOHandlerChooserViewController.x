#import "../HBLOHandlerController.h"
#import "HBLOHandlerChooserViewController.h"
#import "HBLOOpenBrowserActivity.h"
#import "HBLOOpenURLActivity.h"
#import <MobileCoreServices/LSApplicationProxy.h>
#import <MobileCoreServices/LSApplicationWorkspace.h>
#import <UIKit/UIActivityViewController+Private.h>
#import <version.h>

@implementation HBLOHandlerChooserViewController {
	NSDictionary *_openOperationOptions;
}

@dynamic completionHandler;

- (instancetype)initWithURL:(NSURL *)url openOperationOptions:(NSDictionary *)openOperationOptions {
	self = [self initWithActivityItems:@[ [url copy] ] applicationActivities:nil];

	if (self) {
		_openOperationOptions = [openOperationOptions copy];
	}

	return self;
}

- (HBLOOpenURLActivity *)_activityForURL:(NSURL *)url bundleIdentifier:(NSString *)bundleIdentifier {
	return [[[HBLOOpenURLActivity alloc] initWithURL:url bundleIdentifier:bundleIdentifier openOperationOptions:_openOperationOptions] autorelease];
}

- (HBLOOpenURLActivity *)_browserActivityForURL:(NSURL *)url bundleIdentifier:(NSString *)bundleIdentifier {
	return [[[HBLOOpenBrowserActivity alloc] initWithURL:url bundleIdentifier:bundleIdentifier openOperationOptions:_openOperationOptions] autorelease];
}

- (NSArray *)_browserActivitiesForURL:(NSURL *)url {
	if (![url.scheme isEqualToString:@"http"] && ![url.scheme isEqualToString:@"https"]) {
		return nil;
	}

	static dispatch_once_t onceToken;
	static NSDictionary *URLSchemeMap;
	dispatch_once(&onceToken, ^{
		URLSchemeMap = [[NSDictionary alloc] initWithContentsOfURL:[[NSBundle bundleWithPath:@"/Library/Frameworks/Opener.framework"] URLForResource:@"URLSchemeMap" withExtension:@"plist"]];
	});

	NSMutableArray *activities = [NSMutableArray array];
	[activities addObject:[self _browserActivityForURL:url bundleIdentifier:@"com.apple.mobilesafari"]];

	NSDictionary *browsers = URLSchemeMap[@"Browsers"];

	for (NSString *key in browsers.allKeys) {
		NSDictionary *values = browsers[key];
		NSURL *newURL = nil;

		if (values[@"x-callback-url"]) {
			newURL = [NSURL URLWithString:[NSString stringWithFormat:values[@"x-callback-url"], [url.absoluteString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]]]];
		} else {
			NSString *newScheme = nil;

			if ([url.scheme isEqualToString:@"http"] && values[@"http"]) {
				newScheme = values[@"http"];
			} else if ([url.scheme isEqualToString:@"https"] && values[@"https"]) {
				newScheme = values[@"https"];
			}

			if (newScheme) {
				NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:YES];
				urlComponents.scheme = newScheme;
				newURL = urlComponents.URL;
			}
		}

		if (newURL) {
			NSArray *apps = [[LSApplicationWorkspace defaultWorkspace] applicationsAvailableForHandlingURLScheme:newURL.scheme];

			if (apps.count > 0) {
				[activities addObject:[self _browserActivityForURL:newURL bundleIdentifier:key]];
			}
		}
	}

	return activities;
}

- (NSArray *)_availableActivitiesForItems:(NSArray *)items applicationExtensionActivities:(NSArray *)applicationExtensionActivities {
	if (items.count != 1 || ![items[0] isKindOfClass:NSURL.class]) {
		return nil;
	}

	NSURL *url = items[0];
	NSMutableArray *newActivities = [NSMutableArray arrayWithArray:[self _browserActivitiesForURL:url]];

	NSArray *apps = [[LSApplicationWorkspace defaultWorkspace] applicationsAvailableForHandlingURLScheme:url.scheme];

	for (LSApplicationProxy *app in apps) {
		if ([app.applicationIdentifier isEqualToString:@"com.apple.mobilesafari"]) {
			continue;
		}

		[newActivities addObject:[[HBLOOpenURLActivity alloc] initWithURL:url bundleIdentifier:app.applicationIdentifier openOperationOptions:_openOperationOptions]];
	}

	NSArray *replacements = [[HBLOHandlerController sharedInstance] getReplacementsForURL:url sender:nil];

	if (replacements) {
		for (NSURL *replacementURL in replacements) {
			NSArray *apps = [[LSApplicationWorkspace defaultWorkspace] applicationsAvailableForHandlingURLScheme:replacementURL.scheme];

			for (LSApplicationProxy *app in apps) {
				if ([app.applicationIdentifier isEqualToString:@"com.apple.mobilesafari"]) {
					continue;
				}

				[newActivities addObject:[[HBLOOpenURLActivity alloc] initWithURL:replacementURL bundleIdentifier:app.applicationIdentifier openOperationOptions:_openOperationOptions]];
			}
		}
	}

	NSArray *activities = [super _availableActivitiesForItems:items applicationExtensionActivities:applicationExtensionActivities];

	for (UIActivity *activity in activities) {
		if ([activity isKindOfClass:%c(UISocialActivity)] || [activity isKindOfClass:%c(UIMessageActivity)] || [activity isKindOfClass:%c(UIMailActivity)]) {
			continue;
		}

		[newActivities addObject:activity];
	}

	return newActivities;
}

#pragma mark - Memory management

- (void)dealloc {
	[_openOperationOptions release];

	[super dealloc];
}

@end
