FIXADDR
========================================

固定映射这些地址指向物理内存中的随机位置。相对于内核空间起始处的线性映射，在该映射内部的虚拟地址
和物理地址之间的关联不是预设的，而可以自由定义，但定义后不能改变。固定映射区域会一直延伸到虚拟
地址空间顶端。

path: include/linux/asm/fixmap.h
```
#define FIXADDR_START      0xfff00000UL
#define FIXADDR_END        0xfffe0000UL
#define FIXADDR_TOP        (FIXADDR_END - PAGE_SIZE)
```