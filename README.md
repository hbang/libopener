# Opener
Opener is a developer library for overriding link destinations. Handler packages instruct Opener whether to change the URL that’s about to be opened. For examples, refer to the source of [LinkOpener](https://github.com/hbang/LinkOpener) and [MapsOpener](https://github.com/hbang/MapsOpener).

All iOS versions since 5.0 are supported, on all devices.

Documentation is available at **[hbang.github.io/libopener](https://hbang.github.io/libopener/)**.

## Creating an Opener handler
Make sure Opener is already installed on your device.

Theos includes headers and a linkable framework for Opener, so you don’t need to worry about copying files over from your device.

To develop a handler, create a bundle project. You can do this with a Theos makefile similar to this one:

```make
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = MyAwesomeHandler
MyAwesomeHandler_FILES = XXXMyAwesomeHandler.m
MyAwesomeHandler_INSTALL_PATH = /Library/Opener
MyAwesomeHandler_EXTRA_FRAMEWORKS = Opener

include $(THEOS_MAKE_PATH)/bundle.mk
```

A handler class subclasses from [HBLOHandler](https://hbang.github.io/libopener/Classes/HBLOHandler.html). Here is a simple example:

```objc
#import <Opener/Opener.h>

@interface XXXMyAwesomeHandler : HBLOHandler

@end
```

```objc
#import "XXXMyAwesomeHandler.h"

@implementation XXXMyAwesomeHandler

- (instancetype)init {
	self = [super init];

	if (self) {
		self.name = @"My Awesome Handler";
		self.identifier = @"com.example.myawesomehandler";
	}

	return self;
}

- (id)openURL:(NSURL *)url sender:(NSString *)sender {
	if (([url.scheme isEqualToString:@"http"] || [url.scheme isEqualToString:@"https"])
		&& [url.host isEqualToString:@"hbang.ws"]) {
		return [NSURL URLWithString:[NSString stringWithFormat:@"hbang://open%@", url.path]];
	}

	return nil;
}

@end
```

In this example, URLs being opened that are web pages (http:// or https:// scheme) and have a hostname of `hbang.ws` will be overridden to open a hypothetical app that supports the `hbang://` URI scheme. This means `https://hbang.ws/apps/` turns into `hbang://open/apps/`.

You must also add `ws.hbang.libopener` to the `Depends:` list in your control file. If Opener isn’t present on the device, your binaries will fail to load. For example:

```
Depends: mobilesubstrate, something-else, some-other-package, ws.hbang.libopener (>= 3.1.2)
```

You should specify the current version of Opener as the minimum requirement, so you can guarantee all features you use are available.

## License
Licensed under the Apache License, version 2.0. Refer to [LICENSE.md](LICENSE.md).
