Memory
========================================

Initialization
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/init/mm/README.md

Layout
----------------------------------------

### ARM

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/mm/README.md

### ARM64

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm64/mm/README.md

Manager
----------------------------------------

内存管理的实现涵盖了许多领域：

### Data Structure

内存中的物理内存页的管理

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/mmzone.h/README.md

### Memblock

系统启动过程中内存管理

https://github.com/novelinux/linux-4.x.y/tree/master/mm/memblock.c/README.md

### Buddy

分配大块内存的伙伴系统

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/README.md

### Slab

分配较小块内存的slab、slub和slob分配器；

https://github.com/novelinux/linux-4.x.y/tree/master/mm/slab.c/README.md

### Vmalloc

分配非连续内存块的vmalloc机制；

https://github.com/novelinux/linux-4.x.y/tree/master/mm/vmalloc.c/README.md

* 进程的地址空间。

https://github.com/novelinux/linux-4.x.y/tree/master/mm/task_vm_layout.md
