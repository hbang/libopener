include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = libopener
libopener_FILES = $(wildcard *.m) $(wildcard *.x)
libopener_INSTALL_PATH = /Library/PreferenceBundles
libopener_FRAMEWORKS = UIKit
libopener_PRIVATE_FRAMEWORKS = Preferences AppSupport
libopener_EXTRA_FRAMEWORKS = CepheiPrefs Opener
libopener_CFLAGS = -include ../Global.h -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences
	cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/libopener.plist
