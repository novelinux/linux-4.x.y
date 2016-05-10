LOCAL_PATH := $(my-dir)

include $(CLEAR_VARS)

LOCAL_SRC_FILES := elf.c
LOCAL_MODULE := elf
LOCAL_MODULE_TAGS := optional

include $(BUILD_EXECUTABLE)
