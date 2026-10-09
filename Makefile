ARCHS = arm64
TARGET = iphone:clang:latest:13.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = QuickNotesPanel
QuickNotesPanel_FILES = Tweak.xm
QuickNotesPanel_FRAMEWORKS = UIKit Foundation
QuickNotesPanel_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
QuickNotesPanel_INSTALL = 0

include $(THEOS_MAKE_PATH)/tweak.mk
