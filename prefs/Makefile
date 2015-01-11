TARGET = :clang::5.0
ARCHS = armv7 arm64

include theos/makefiles/common.mk

BUNDLE_NAME = libopener
libopener_FILES = $(wildcard *.m)
libopener_INSTALL_PATH = /Library/PreferenceBundles
libopener_FRAMEWORKS = UIKit
libopener_PRIVATE_FRAMEWORKS = Preferences AppSupport
libopener_LIBRARIES = cepheiprefs opener
libopener_LDFLAGS = -L../debs/obj

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences
	cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/libopener.plist
