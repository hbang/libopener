TARGET = iphone::5.1:5.0

include theos/makefiles/common.mk

LIBRARY_NAME = libopener
libopener_FILES = HBLibOpener.mm Tweak.xm
libopener_LDFLAGS = -lsubstrate

include $(THEOS_MAKE_PATH)/library.mk

after-stage::
	@mkdir -p $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries
	@ln -s /usr/lib/libopener.dylib $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries/libopener.dylib
	@cp libopener.plist $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries/libopener.plist

after-install::
	install.exec "killall -9 SpringBoard"
