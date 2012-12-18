# libopener
Developer library for overriding link destinations. [GPL licensed.](http://hbang.ws/s/gpl)

## Using libopener in your own tweak
This assumes that your project is a tweak using the [Theos](https://github.com/DHowett/theos) build system.

1. [Grab the header](https://github.com/hbang/libopener/blob/master/HBLibOpener.h) and place it in your project directory.
2. In your tweak's code (usually lives in `Tweak.xm`), add the following like to the top to import the header:

        #import "HBLibOpener.h"
3. Append the following code to your `%ctor`, or wrap it in `%ctor {` ... `}` if you don't have one:

        [[HBLibOpener sharedInstance] registerHandlerWithName:@"YourTweakName" block:^(NSURL *url) {
        	if (/* the url should be replaced */) {
        		return [NSURL URLWithString:/* new url */];
        	}

        	return (objc_object *)nil;
        }];

    The handler name must be changed, otherwise your handler may not be registered if another tweak has the same name. (This depends on the order that the tweaks were loaded - MobileSubstrate loads tweaks in alphabetical order.)
    The block will be called for all calls to SpringBoard's core URL opener method, so try not to use too much CPU or perform any network operations in it.
4. Open your `Makefile` and append the following before `include $(THEOS_MAKE_PATH)/tweak.mk`, replacing `TweakName` with the name matching the similar lines above:

        TweakName_LDFLAGS = -lopener
5. Open your `control` file and append `ws.hbang.libopener` to the `Depends:` list.
6. If you haven't already, copy the library to $THEOS/lib:

        scp root@yourdevice.local:/usr/lib/libopener.dylib $THEOS/lib/libopener.dylib
7. `make` and have fun!
