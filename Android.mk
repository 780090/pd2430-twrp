LOCAL_PATH := $(call my-dir)

ifeq ($(TARGET_DEVICE),PD2430)
include $(call all-subdir-makefiles,$(LOCAL_PATH))
endif
