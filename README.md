# libopener
Developer library for overriding link destinations. Licensed under [GPLv3](http://hbang.ws/s/gpl).

## Using libopener in your own tweak
This assumes that your project is a tweak using the [Theos](https://github.com/DHowett/theos) build system.

1. Grab the [HBLibOpener.h](https://github.com/hbang/libopener/blob/master/HBLibOpener.h) header and place it in `$THEOS/include`.
2. Import it in your code:

    ```objc
#import "HBLibOpener.h"
    ```
3. Implement this code in a `%ctor`:

    ```objc
[[HBLibOpener sharedInstance] registerHandlerWithName:@"YourTweakName" block:^(NSURL *url) {
    if (/* the url should be replaced */) {
        return [NSURL URLWithString:/* new url */];
    }

    return (id)nil;
}];
    ```

    The handler name must be changed, otherwise your handler may not be registered if another tweak has the same name. (This depends on the order that the tweaks were loaded - MobileSubstrate loads tweaks in alphabetical order.)
    The block will be called for all calls to SpringBoard's core URL opener method, so try not to use too much CPU or perform any network operations in it.
4. Open your `Makefile` and append the following before `include $(THEOS_MAKE_PATH)/tweak.mk`:

    ```make
TweakName_LIBRARIES = opener
    ```
5. Open your `control` file and append `ws.hbang.libopener` to the `Depends:` list.
6. If you haven't already, copy the library to $THEOS/lib:

    ```bash
scp root@yourdevice.local:/usr/lib/libopener.dylib $THEOS/lib/libopener.dylib
    ```
7. `make` and have fun!
