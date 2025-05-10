TARGET := iphone:clang:16.5:14.0
ARCHS := arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := zxPluginsInject

$(TWEAK_NAME)_FILES := $(shell find src -type f -name "*.*m") fishhook/fishhook.c
$(TWEAK_NAME)_CFLAGS := -fobjc-arc -Os
$(TWEAK_NAME)_LOGOS_DEFAULT_GENERATOR := internal

include $(THEOS_MAKE_PATH)/tweak.mk

