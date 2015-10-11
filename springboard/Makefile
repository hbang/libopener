TARGET = :clang::8.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = OpenerSpringBoard
OpenerSpringBoard_FILES = $(wildcard *.x) $(wildcard *.m)
OpenerSpringBoard_FRAMEWORKS = MobileCoreServices UIKit
OpenerSpringBoard_LIBRARIES = opener
OpenerSpringBoard_LDFLAGS = -L$(THEOS_OBJ_DIR)

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec spring
