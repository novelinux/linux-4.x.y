Linux内存管理
========================================

概述
----------------------------------------

内存管理的实现涵盖了许多领域：

* 内存中的物理内存页的管理；

* 分配大块内存的伙伴系统；

* 分配较小块内存的slab、slub和slob分配器；

* 分配非连续内存块的vmalloc机制；

* 进程的地址空间。

就我们所知，Linux内核一般将处理器的虚拟地址空间划分为两个部分。底部比较大的部分用于用户进程，
顶部则专用于内核。虽然（在两个用户进程之间的）上下文切换期间会改变下半部分，但虚拟地址空间
的内核部分总是保持不变。地址空间在用户进程和内核之间划分的典型比例为3∶1。给出4 GiB虚拟地址空间，
3 GiB将用于用户空间而1 GiB将用于内核。通过修改相关的配置选项可以改变该比例。但只有对非常特殊的
配置和应用程序，这种修改才会带来好处。目前，我们只需假定比例为3∶1,其他比例以后再讨论。

硬件相关
----------------------------------------

### ARM

#### msm8960

https://github.com/novelinux/arch-arm-msm-8960/tree/master/memory_map.md

#### aries

https://github.com/novelinux/arch-arm-msm-8960/tree/master/memory_layout.md

#### MMU

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/mm/mmu.c/README.md

物理内存管理
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/mmzone.h/README.md

初始化内存管理
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/init/mm/README.md

进程虚拟地址空间
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/task_vm_layout.md
