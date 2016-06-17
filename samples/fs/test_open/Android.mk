LOCAL_PATH := $(call my-dir)

# target
include $(CLEAR_VARS)

LOCAL_SRC_FILES := open.c
LOCAL_STATIC_LIBRARIES := libcutils
LOCAL_C_INCLUDES := system/core/include
LOCAL_MODULE := open

include $(BUILD_EXECUTABLE)
