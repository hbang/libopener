TARGET = :clang::5.0

include $(THEOS)/makefiles/common.mk

FRAMEWORK_NAME = Opener
Opener_FILES = $(wildcard *.x) $(wildcard *.m)
Opener_FRAMEWORKS = MobileCoreServices UIKit
Opener_PRIVATE_FRAMEWORKS = AppSupport
Opener_LIBRARIES = cephei rocketbootstrap substrate
Opener_CFLAGS = -include HBLOGlobal.h

SUBPROJECTS = prefs

include $(THEOS_MAKE_PATH)/framework.mk
include $(THEOS_MAKE_PATH)/aggregate.mk

after-stage::
	mkdir -p $(THEOS_STAGING_DIR)/usr/lib
	ln -s /Library/Frameworks/Opener.framework/Opener $(THEOS_STAGING_DIR)/usr/lib/libopener.dylib

	mkdir -p $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries
	ln -s /Library/Frameworks/Opener.framework/Opener $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries/libopener.dylib
	cp libopener.plist $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries/libopener.plist

	mkdir -p $(THEOS_STAGING_DIR)/Library/Opener $(THEOS_STAGING_DIR)/usr/include/libopener
	cp HBLibOpener.h HBLOHandler.h HBLOHandlerDelegate.h $(THEOS_STAGING_DIR)/usr/include/libopener
	rsync -ra $(THEOS_STAGING_DIR)/Library/Frameworks/Opener.framework $(THEOS)/lib/
	rsync -ra $(THEOS_STAGING_DIR)/usr/include/libopener/ $(THEOS)/include/libopener

after-install::
ifeq ($(RESPRING),0)
	install.exec "killall Preferences; sleep 0.2; sbopenurl 'prefs:root=Opener'"
else
	install.exec spring
endif
