FIXADDR
========================================

path: include/linux/asm/fixmap.h
```
#define FIXADDR_START      0xfff00000UL
#define FIXADDR_END        0xfffe0000UL
#define FIXADDR_TOP        (FIXADDR_END - PAGE_SIZE)
```