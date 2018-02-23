export TARGET = iphone:latest:5.0
export ADDITIONAL_CFLAGS = -Wextra -Wno-unused-parameter

INSTALL_TARGET_PROCESSES = Preferences

DOCS_STAGING_DIR = _docs
DOCS_OUTPUT_PATH = docs

include $(THEOS)/makefiles/common.mk

FRAMEWORK_NAME = Opener
Opener_FILES = $(wildcard *.x) $(wildcard *.m)
Opener_PUBLIC_HEADERS = Opener.h HBLibOpener.h HBLOHandler.h
Opener_FRAMEWORKS = MobileCoreServices
Opener_PRIVATE_FRAMEWORKS = SpringBoardServices
Opener_EXTRA_FRAMEWORKS = Cephei CydiaSubstrate
Opener_CFLAGS = -include Global.h -fobjc-arc
Opener_INSTALL_PATH = /usr/lib/Opener

SUBPROJECTS = openerd client prefs

include $(THEOS_MAKE_PATH)/framework.mk
include $(THEOS_MAKE_PATH)/aggregate.mk

after-Opener-stage::
	@# create directories
	$(ECHO_NOTHING)mkdir -p \
		$(THEOS_STAGING_DIR)/DEBIAN $(THEOS_STAGING_DIR)/usr/lib \
		$(THEOS_STAGING_DIR)/Library/Frameworks \
		$(THEOS_STAGING_DIR)/Library/LaunchDaemons \
		$(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries$(ECHO_END)

	@# {pre,post}inst -> /DEBIAN/
	$(ECHO_NOTHING)cp preinst postinst prerm $(THEOS_STAGING_DIR)/DEBIAN$(ECHO_END)

	@# /Library/Frameworks/Opener.framework -> /usr/lib/Opener/Opener.framework
	$(ECHO_NOTHING)ln -s /usr/lib/Opener/Opener.framework $(THEOS_STAGING_DIR)/Library/Frameworks/Opener.framework$(ECHO_END)

	@# /usr/lib/Opener/Opener.framework/Opener -> /Library/MobileSubstrate/DynamicLibraries/libopener.dylib
	$(ECHO_NOTHING)ln -s /usr/lib/Opener/Opener.framework/Opener $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries/libopener.dylib$(ECHO_END)

	@# libopener.plist -> /Library/MobileSubstrate/DynamicLibraries/libopener.plist
	$(ECHO_NOTHING)cp libopener.plist $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries/libopener.plist$(ECHO_END)

	$(ECHO_NOTHING)cp openerd/ws.hbang.openerd.plist $(THEOS_STAGING_DIR)/Library/LaunchDaemons$(ECHO_END)

after-install::
ifeq ($(RESPRING),1)
	install.exec "spring 'prefs:root=Opener'"
else
	install.exec "uiopen 'prefs:root=Opener'"
endif

docs::
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
