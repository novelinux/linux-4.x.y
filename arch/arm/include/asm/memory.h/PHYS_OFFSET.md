PHYS_OFFSET
========================================

Physical start address of the first bank of RAM.

path: arch/arm/include/asm/memory.h
```
/*
 * PLAT_PHYS_OFFSET is the offset (from zero) of the start of physical
 * memory.  This is used for XIP and NoMMU kernels, and on platforms that don't
 * have CONFIG_ARM_PATCH_PHYS_VIRT. Assembly code must always use
 * PLAT_PHYS_OFFSET and not PHYS_OFFSET.
 */
#define PLAT_PHYS_OFFSET    UL(CONFIG_PHYS_OFFSET)
...
#define PHYS_OFFSET    PLAT_PHYS_OFFSET
```

CONFIG_PHYS_OFFSET
----------------------------------------

### aries

path: arch/arm/configs/aries-perf-eng_defconfig
```
CONFIG_PHYS_OFFSET=0x80200000
```