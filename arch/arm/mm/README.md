Memory Layout
========================================

在ARM系统上内核通常将总的4 GiB可用虚拟地址空间按3 : 1的比例划分。低端3 GiB用于用户状态应用程序，
而高端的1 GiB则专用于内核。尽管在分配内核的虚拟地址空间时，当前系统上下文是不相干的，但每个过程
都有自身特定的地址空间。这些划分主要的动机如下所示:

* 在用户应用程序的执行切换到核心态时（这总是会发生，例如在使用系统调用或发生周期性的时钟中断时），
  内核必须装载在一个可靠的环境中。因此有必要将地址空间的一部分分配给内核专用。
* 物理内存页则映射到内核地址空间的起始处，以便内核直接访问，而无需复杂的页表操作。

如果所有物理内存页都映射到用户空间过程能访问的地址空间中，如果在系统上有几个应用程序在运行，
将导致严重的安全问题。每个应用程序都能够读取和修改其他进程在物理内存中的内存区。显然必须不惜
任何代价防止这种情况出现。虽然用于用户层过程的虚拟地址部分随进程切换而改变，但是内核部分总是
相同的。下图概括了这种情况:

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/mm/res/user-kernel-mm.jpg

aries virtual memory layout
----------------------------------------

### (0xc0000000 ~ 0xffffffff)

内核地址空间自身又分为各个段，如下所示:

```
[    0.000000] Memory: 140MB 74MB 4MB 7MB 255MB 88MB 1433MB = 2001MB total
[    0.000000] Memory: 1859388k/1859388k available, 207040k reserved, 1297404K highmem
[    0.000000] Virtual kernel memory layout:
[    0.000000]     vector  : 0xffff0000 - 0xffff1000   (   4 kB)
[    0.000000]     timers  : 0xfffef000 - 0xffff0000   (   4 kB)
[    0.000000]     fixmap  : 0xfff00000 - 0xfffe0000   ( 896 kB)
[    0.000000]     vmalloc : 0xf0000000 - 0xff000000   ( 240 MB)
[    0.000000]     lowmem  : 0xc0000000 - 0xef800000   ( 760 MB)
[    0.000000]     pkmap   : 0xbfe00000 - 0xc0000000   (   2 MB)
[    0.000000]     modules : 0xbf000000 - 0xbfe00000   (  14 MB)
[    0.000000]       .text : 0xc0008000 - 0xc0e07f80   (14336 kB)
[    0.000000]       .init : 0xc0f00000 - 0xc101df40   (1144 kB)
[    0.000000]       .data : 0xc101e000 - 0xc121aac0   (2035 kB)
[    0.000000]        .bss : 0xc121aae4 - 0xc1a4e2e4   (8398 kB)
```

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/mm/res/kernel-mm-layout.jpg

#### lowmem (0xc0000000 - 0xef800000)

(0xc0000000 ~ 0xef800000) <--> (0x80200000 ~ 0xafa00000)

https://github.com/novelinux/linux-4.x.y/blob/master/arch/arm/mm/mmu.c/map_lowmem.md

lowmem(低端内存，即zone[Normal])。这段映射是一对一的平坦映射，也就是说kernel初始化这段映射后，
页表将不会改变。这样即可以省去不断的修改页表，刷新TLB（TLB可以认为是页表的硬件cache，如果访问
的虚拟地址的页表在这个cache中，则CPU无需访问DDR寻址页表了，这样可以提高IO效率）了。显然这段
地址空间非常珍贵，因为这段映射的效率高。

直接映射区域从0xC0000000到high_memory地址。直接映射的边界由high_memory指定:

https://github.com/novelinux/linux-4.x.y/blob/master/arch/arm/mm/mmu.c/sanity_check_meminfo.md

这种方案有一问题。由于内核的虚拟地址空间只有1 GiB，最多只能映射1 GiB物理内存。ARM系统最大的内存
配置可以达到4 GiB，引出的一个问题是，如何处理剩下的内存？这里有个坏消息。如果物理内存超过896 MiB，
则内核无法直接映射全部物理内存。该值甚至比此前提到的最大限制1GiB还小，因为内核必须保留地址空间
最后的128 MiB用于其他目的，将这128 MiB加上直接映射的896 MiB内存，则得到内核虚拟地址空间的总数为
1024 MiB = 1 GiB。内核使用两个经常使用的缩写normal和highmem，来区分是否可以直接映射的页帧。
内核移植的每个体系结构都必须提供两个宏，用于一致映射的内核虚拟内存部分，进行物理和虚拟地址之间的
转换:

* __pa(vaddr)返回与虚拟地址vaddr相关的物理地址。
* __va(paddr)则计算出对应于物理地址paddr的虚拟地址。

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/include/asm/memory.h/__pa_vs__va.md

两个函数都用void指针和unsigned long操作，因为这两个数据类型对表示内存地址是同样适用的。切记，
这些函数不适用于处理虚拟地址空间中的任意地址，只能用于其中的一致映射部分！这就是为什么这两个
函数通常用简单的线性变换实现，而无需通过页表迂回的原因。

#### vmalloc (0xef800000 - 0xff000000)

虚拟内存中连续、但物理内存中不连续的内存区，可以在vmalloc区域分配。该机制通常用于用户过程，内核
自身会试图尽力避免非连续的物理地址。内核通常会成功，因为大部分大的内存块都在启动时分配给内核，
那时内存的碎片尚不严重。但在已经运行了很长时间的系统上，在内核需要物理内存时，就可能出现可用空间
不连续的情况。此类情况，主要出现在动态加载模块时。

VMALLOC_START和VMALLOC_END定义了vmalloc区域的开始和结束，该区域用于物理上不连续的内核映射:

https://github.com/novelinux/linux-4.x.y/blob/master/arch/arm/include/asm/pgtable.h/VMALLOC.md

#### pkmap (0xbfe00000 - 0xc0000000)

持久映射用于将高端内存域中的非持久页映射到内核中。

https://github.com/novelinux/linux-4.x.y/blob/master/arch/arm/mm/mmu.c/kmap_init.md

PKMAP_BASE定义了pkmap的起始位置:

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/include/asm/highmem.h/PKMAP_BASE.md

#### fixmap (0xfff00000 - 0xfffe0000)

固定映射是与物理地址空间中的固定页关联的虚拟地址空间项，但具体关联的页帧可以自由选择。它与通过
固定公式与物理内存关联的直接映射页相反，虚拟固定映射地址与物理内存位置之间的关联可以自行定义，
关联建立后内核总是会觉察到的。

固定映射地址的优点在于，在编译时对此类地址的处理类似于常数，内核一启动即为其分配了物理地址。
此类地址的反引用比普通指针要快速。内核会确保在上下文切换其间，对应于固定映射的页表项不会从
TLB刷出，因此在访问固定映射的内存时，总是通过TLB高速缓存取得对应的物理地址。对每个固定映射
地址都会创建一个常数，加入到fixed_addresses枚举值列表中:

https://github.com/novelinux/linux-4.x.y/blob/master/arch/arm/include/asm/fixmap.h/enum_fixed_addresses.md

内核提供了fix_to_virt函数，用于计算固定映射常数的虚拟地址。

https://github.com/novelinux/linux-4.x.y/tree/master/include/asm-generic/fixmap.h/__firx_to_virt.md

FIXADDR_START和FIXADDR_END定义了fixmap区域开始和结束地址:

https://github.com/novelinux/linux-4.x.y/blob/master/arch/arm/include/asm/fixmap.h/FIXADDR_XXX.md

##### 映射过程

https://github.com/novelinux/linux-4.x.y/blob/master/arch/arm/mm/mmu.c/kmap_init.md

aries physical memory layout
----------------------------------------

```
# cat /proc/iomap
...
80200000-88dfffff : System RAM
  80208000-81007f7f : Kernel code
  8121e000-81c4e2e3 : Kernel data
89000000-8d9fffff : System RAM
8ec00000-8effffff : System RAM
8f700000-8fdfffff : System RAM
8ff00000-9fdfffff : System RAM
  8ff00000-8ff3ffff : rmtfs
a0000000-a57fffff : System RAM
a5900000-ff2fefff : System RAM
```

highmem
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/appendix/highmem/README.md