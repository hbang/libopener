#import "HBLOAboutListController.h"
#import <Preferences/PSSpecifier.h>

@implementation HBLOAboutListController

+ (NSString *)hb_specifierPlist {
	return @"About";
}

- (void)openTranslations {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.hbang.ws/translations/"]];
}

@end
