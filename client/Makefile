include $(THEOS)/makefiles/common.mk

TWEAK_NAME = OpenerClient
OpenerClient_FILES = $(wildcard *.x) $(wildcard *.m)
OpenerClient_FRAMEWORKS = MobileCoreServices
OpenerClient_EXTRA_FRAMEWORKS = Cephei Opener
OpenerClient_CFLAGS = -include ../Global.h -fobjc-arc
OpenerClient_LDFLAGS = -F$(THEOS_OBJ_DIR)

include $(THEOS_MAKE_PATH)/tweak.mk
