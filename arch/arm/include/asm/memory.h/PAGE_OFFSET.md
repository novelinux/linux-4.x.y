PAGE_OFFSET
========================================

Virtual start address of the first bank of RAM.  During the kernel
boot phase, virtual address PAGE_OFFSET will be mapped to physical
address PHYS_OFFSET, along with any other mappings you supply.
This should be the same value as TASK_SIZE.

path: arch/arm/include/asm/memory.h
```
/* PAGE_OFFSET - the virtual address of the start of the kernel image */
#define PAGE_OFFSET		UL(CONFIG_PAGE_OFFSET)
```

CONFIG_PAGE_OFFSET
----------------------------------------

### aries

path: arch/arm/configs/aries-perf-eng_defconfig
```
CONFIG_PAGE_OFFSET=0xC0000000
```
