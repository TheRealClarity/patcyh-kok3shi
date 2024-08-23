ARCHS = arm64 armv7
TARGET := iphone:clang:11.4:8.3

FINALPACKAGE=1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = patcyh

patcyh_FILES = patcyh.mm

include $(THEOS_MAKE_PATH)/tweak.mk
