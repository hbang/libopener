# Opener
Opener is a developer library for overriding link destinations. Handler packages instruct Opener whether to change the URL that’s about to be opened. For examples, refer to the source of [LinkOpener](https://github.com/hbang/LinkOpener) and [MapsOpener](https://github.com/hbang/MapsOpener).

All iOS versions since 5.0 are supported, on all devices.

Documentation is available at **[hbang.github.io/libopener](https://hbang.github.io/libopener/)**.

## Integrating Opener into your Theos projects
It’s really easy to integrate Opener into a Theos project. First, install Opener on your device.

Now, copy the dynamic libraries and headers into the location you cloned Theos to. (Hopefully you have `$THEOS`, `$THEOS_DEVICE_IP`, and `$THEOS_DEVICE_PORT` set and exported in your shell.)

```
scp -rP $THEOS_DEVICE_PORT root@$THEOS_DEVICE_IP:/Library/Frameworks/Opener.framework $THEOS/lib
```

Next, for all projects that will be using Opener, add it to the instance’s libraries:

```
MyAwesomeTweak_EXTRA_FRAMEWORKS += Opener
```

You can now use Opener in your project.

Please note that Opener is now a framework, instead of a library. Frameworks are only properly supported with [kirb/theos](https://github.com/kirb/theos); other variants of Theos may or may not support it.

## License
Licensed under [Apache License, version 2.0](https://github.com/hbang/libopener/blob/master/LICENSE.md).
