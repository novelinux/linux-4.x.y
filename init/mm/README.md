内存初始化
========================================

在内存管理的上下文中，初始化（initialization）可以有多种含义。在许多CPU上，必须显式设置适于
Linux内核的内存模型。例如，在IA-32系统上需要切换到保护模式，然后内核才能检测可用内存和寄存器。
在初始化过程中，还必须建立内存管理的数据结构，以及其他很多事务。因为内核在内存管理完全初始化
之前就需要使用内存，在系统启动过程期间，使用了一个额外的简化形式的内存管理模块，然后又丢弃掉。
因为内存管理初始化中特定于CPU的部分使用了底层体系结构许多次要、微妙的细节，这些与内核的结构
没什么关系，最多不过是汇编语言程序设计的最佳实践而已.

对相关数据结构的初始化是从全局启动例程start_kernel中开始的，该例程在加载内核并激活各个
子系统之后执行。由于内存管理是内核一个非常重要的部分，因此在特定于体系结构的设置步骤中
检测内存并确定系统中内存的分配情况后，会立即执行内存管理的初始化。

setup_arch
----------------------------------------

### ARM

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/kernel/setup.c/setup_arch.md

setup_per_cpu_areas
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/percpu.c/setup_per_cpu_areas.md

build_all_zonelists
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/build_all_zonelists.md

mm_init
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/init/main.c/mm_init.md

setup_per_cpu_pageset
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/setup_per_cpu_pageset.md
