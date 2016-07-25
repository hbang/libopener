TARGET = iphone:clang:latest:5.0

DOCS_STAGING_DIR = _docs
DOCS_OUTPUT_PATH = docs

include $(THEOS)/makefiles/common.mk

FRAMEWORK_NAME = Opener
Opener_FILES = $(wildcard *.x) $(wildcard *.m)
Opener_PUBLIC_HEADERS = HBLibOpener.h HBLOHandler.h HBLOHandlerDelegate.h
Opener_FRAMEWORKS = MobileCoreServices UIKit
Opener_PRIVATE_FRAMEWORKS = AppSupport
Opener_EXTRA_FRAMEWORKS = Cephei
Opener_LIBRARIES = rocketbootstrap substrate
Opener_CFLAGS = -include Global.h -fobjc-arc

SUBPROJECTS = prefs

include $(THEOS_MAKE_PATH)/framework.mk
include $(THEOS_MAKE_PATH)/aggregate.mk

after-Opener-stage::
	# create directories
	mkdir -p $(THEOS_STAGING_DIR)/DEBIAN $(THEOS_STAGING_DIR)/usr/lib

	# preinst -> DEBIAN/preinst
	cp preinst $(THEOS_STAGING_DIR)/DEBIAN

	# libopener.dylib -> Opener.framework
	ln -s /Library/Frameworks/Opener.framework/Opener $(THEOS_STAGING_DIR)/usr/lib/libopener.dylib

	# Opener -> libopener.dylib
	mkdir -p $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries
	ln -s /Library/Frameworks/Opener.framework/Opener $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries/libopener.dylib
	cp libopener.plist $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries/libopener.plist

after-install::
ifeq ($(RESPRING),0)
	install.exec "killall Preferences; sleep 0.2; sbopenurl 'prefs:root=Opener'"
else
	install.exec spring
endif

docs::
	# eventually, this should probably be in theos.
	# for now, this is good enough :p

	[[ -d "$(DOCS_STAGING_DIR)" ]] && rm -r "$(DOCS_STAGING_DIR)" || true

	-appledoc --project-name Opener --project-company "HASHBANG Productions" --company-id ws.hbang --project-version 3.0 --no-install-docset \
		--keep-intermediate-files --create-html --publish-docset --docset-feed-url "https://hbang.github.io/libopener/xcode-docset.atom" \
		--docset-atom-filename xcode-docset.atom --docset-package-url "https://hbang.github.io/libopener/docset.xar" \
		--docset-package-filename docset --docset-fallback-url "https://hbang.github.io/libopener/" --docset-feed-name Opener \
		--index-desc README.md --no-repeat-first-par \
		--output "$(DOCS_STAGING_DIR)" $(Opener_PUBLIC_HEADERS)

	[[ -d "$(DOCS_OUTPUT_PATH)" ]] || git clone -b gh-pages git@github.com:hbang/libopener.git "$(DOCS_OUTPUT_PATH)"
	rsync -ra "$(DOCS_STAGING_DIR)"/{html,publish}/ "$(DOCS_OUTPUT_PATH)"
	rm -r "$(DOCS_STAGING_DIR)"
