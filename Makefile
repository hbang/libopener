TARGET = :clang::5.0
ARCHS = armv7 arm64

include theos/makefiles/common.mk

THEOS_BUILD_DIR = debs

LIBRARY_NAME = libopener
libopener_FILES = $(wildcard *.xm) $(wildcard *.m)
libopener_PRIVATE_FRAMEWORKS = AppSupport
libopener_LIBRARIES = substrate rocketbootstrap

SUBPROJECTS = prefs

include $(THEOS_MAKE_PATH)/library.mk
include $(THEOS_MAKE_PATH)/aggregate.mk

after-stage::
	@mkdir -p $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries
	@ln -s /usr/lib/libopener.dylib $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries/libopener.dylib
	@cp libopener.plist $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries/libopener.plist

after-install::
ifeq ($(RESPRING),0)
	install.exec "killall Preferences; sleep 0.2; sbopenurl 'prefs:root=Cydia&path=Opener'"
else
	install.exec spring
endif
