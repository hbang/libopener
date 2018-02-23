include $(THEOS)/makefiles/common.mk

TOOL_NAME = openerd
openerd_FILES = $(wildcard *.m)
openerd_INSTALL_PATH = /usr/libexec
openerd_PRIVATE_FRAMEWORKS = MobileCoreServices
openerd_EXTRA_FRAMEWORKS = Opener
openerd_CFLAGS = -include ../Global.h -fobjc-arc
openerd_LDFLAGS = -F$(THEOS_OBJ_DIR)

include $(THEOS_MAKE_PATH)/tool.mk
