TARGET = iphone:latest:9.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = OpenerClient
OpenerClient_FILES = $(wildcard *.x) $(wildcard *.m)
OpenerClient_PRIVATE_FRAMEWORKS = MobileCoreServices
OpenerClient_EXTRA_FRAMEWORKS = Opener
OpenerClient_CFLAGS = -include ../Global.h -fobjc-arc
OpenerClient_LDFLAGS = -F$(THEOS_OBJ_DIR)

include $(THEOS_MAKE_PATH)/tweak.mk
