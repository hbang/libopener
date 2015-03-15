include theos/makefiles/common.mk

TWEAK_NAME = libopenerSpringBoard
libopenerSpringBoard_FILES = $(wildcard *.x) $(wildcard *.m)
libopenerSpringBoard_FRAMEWORKS = MobileCoreServices
libopenerSpringBoard_LIBRARIES = opener
libopenerSpringBoard_LDFLAGS = -L$(THEOS_OBJ_DIR)

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec spring
