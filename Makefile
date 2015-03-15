TARGET = :clang::5.0
ARCHS = armv7 arm64

include theos/makefiles/common.mk

LIBRARY_NAME = libopener
libopener_FILES = $(wildcard *.x) $(wildcard *.m)
libopener_FRAMEWORKS = MobileCoreServices UIKit
libopener_PRIVATE_FRAMEWORKS = AppSupport
libopener_LIBRARIES = cephei rocketbootstrap substrate

SUBPROJECTS = springboard prefs

include $(THEOS_MAKE_PATH)/library.mk
SUBPROJECTS += libopenerspringboard
include $(THEOS_MAKE_PATH)/aggregate.mk

after-stage::
	mkdir -p $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries $(THEOS_STAGING_DIR)/Library/Opener $(THEOS_STAGING_DIR)/usr/include/libopener

	ln -s /usr/lib/libopener.dylib $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries/libopener.dylib
	cp libopener.plist $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries/libopener.plist
	cp HBLibOpener.h HBLOHandler.h HBLOHandlerDelegate.h $(THEOS_STAGING_DIR)/usr/include/libopener
	cp $(THEOS_STAGING_DIR)/usr/lib/libopener.dylib $(THEOS)/lib/libopener.dylib
	cp -r $(THEOS_STAGING_DIR)/usr/include/libopener $(THEOS)/include/libopener

after-install::
ifeq ($(RESPRING),0)
	install.exec "killall Preferences; sleep 0.2; sbopenurl 'prefs:root=Cydia&path=Opener'"
else
	install.exec spring
endif
