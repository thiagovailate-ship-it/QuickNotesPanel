TARGET = iphone:clang:17.5:15.0
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = QuickNotesPanel
QuickNotesPanel_FILES = Tweak.xm

include $(THEOS_MAKE_PATH)/tweak.mk
