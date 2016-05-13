Linux内存管理
========================================

内存管理的实现涵盖了许多领域：

* 内存中的物理内存页的管理；

* 分配大块内存的伙伴系统；

* 分配较小块内存的slab、slub和slob分配器；

* 分配非连续内存块的vmalloc机制；

* 进程的地址空间。


初始化内存管理
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/init/mm/README.md

内存布局
----------------------------------------

### ARM

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/mm/README.md

### ARM64

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm64/mm/README.md

物理内存管理
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/mmzone.h/README.md

进程虚拟地址空间
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/task_vm_layout.md
