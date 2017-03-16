# CMA

原 文：https://lwn.net/Articles/486301/
译 者：滕瑞
领 域：Linux Kernel，Memory Management

连续内存分配（简称CMA） 是一种用于申请大量的，并且物理上连续的内存块的方法，在LWN上可以追溯到2011年6月。
原理虽简单，但是其实现起来却相当复杂，因为需要许多子系统之间相互协作。基于不同人的视角，有很多不同的事需要完成和注意。
在本文中，我会描述如何使用CMA并且如何将其集成到一个特定平台。

从设备驱动作者的角度看，任何事情都不应该被影响。因为CMA是被集成到DMA子系统，所以以前调用
DMA API（例如dma_alloc_coherent()）的地方应该照常工作。事实上，设备驱动永远不需要直接调用CMA API，
因为它是在页和页帧编号（PFNs）上操作而无关总线地址和内核映射，并且也不提供维护缓存一致性的机制。

获取更多信息，可以参考Documentation/DMA-API.txt和Documentation/DMA-API-HOWTO.txt这两份有用的文档。
这两篇文档描述了DMA提供的方法接口及使用用例。

## 架构集成

当然，需要有人在特定的体系架构下将CMA集成到DMA子系统中。这只需要很少的并且相当简单的步骤。

CMA通过在启动阶段预先保留内存。这些内存叫做CMA区域或CMA上下文，稍后返回给伙伴系统从而可以被用作正常申请。
如果要保留内存，则需要恰好在底层“memblock”分配器初始化之后，并在伙伴系统建立之前调用：

```
void dma_contiguous_reserve(phys_addr_t limit)
```

例如，在ARM上，这个方法在arm_memblock_init()中调用，而在x86上这个方法则放在setup_arch()中，写在memblock建立之后。

limit参数确定了不会被用于CMA的物理内存的上限地址。目的是限制CMA上下文并指明DMA可以处理的地址范围。
以ARM为例，limit是arm_dma_limit和arm_lowmem_limit的最小值。如果传入0则允许CMA将其上下文地址尽最大可能设置得最高。
唯一的限制是保留的内存必须属于同一个区域（zone）。

保留内存的大小取决于几个Kconfig选项和一个cma内核参数。我会在本文的后面描述它们。

dma_contiguous_reserve()函数会预留内存并准备给CMA使用。在有些体系架构下（例如，ARM），需要完成一些体系相关的工作。
为了方便这些功能，CMA会调用如下方法：

```
void dma_contiguous_early_fixup(phys_addr_t base, unsigned long size);
```

体系架构的职责要保证提供这个方法，且一并在asm/dma-contiguous.h头文件中提供函数声明。
如果特定的体系架构不需要特定的处理，提供一个空的函数定义即可。

这个函数会很早被调用，因此一些子系统（例如，kmalloc()）尚不可用。此外，这个函数会被多次调用（因为如下面将要介绍的，会存在多个CMA上下文）

第二件需要做的事是将体系架构的DMA实现替换为通用架构的实现。用以下方法分配CMA内存：

```
struct page *dma_alloc_from_contiguous(struct device *dev, int count, unsigned int align);
```

* 第一个参数是需要为之分配内存的设备。
* 第二个参数指定了分配的页数（不是字节或阶）。
* 第三个参数是页阶的校正。这个参数使分配缓存时物理地址按照2^align页对齐。为了防止碎片，这里至少输入0。
  值得注意的是有一个Kconfig选项（CONFIG_CMA_ALIGNMENT）指定了可以接受的最大对齐数值。默认值是8，即256页对齐。

* 返回值是count个数目的页的第一个页。

要释放申请的空间，调用如下方法：

```
bool dma_release_from_congiguous(struct device *dev, struct page *pages, int count);
```

dev和count参数和前面的一致，pages是dma_alloc_from_contiguous()方法返回的指针。
如果传入这个方法的区域不是来自CMA，该方法会返回false。否则它将返回true。这消除了更上层方法跟踪分配来自CMA或其他方法的需要。

注意dma_alloc_from_congiguous()不能用在需要原子请求的上下文中。因为它执行了一些“沉重”的如页移植、直接回收等需要一定时间的操作。
正因为如此，为了使dma_alloc_coherent()及其友元函数工作正常，相关体系需要在原子请求下有不同的方法来分配内存。

最简单的解决方案是在启动时预留一部分内存专门用于原子请求的分配。这其实就是ARM的做法。现存的体系大都已经有了特殊的路径来解决原子分配。

## 特殊内存需求

在这点上，大部分驱动应该“可以工作”。它们使用调用CMA的DMA API。生活是美好的。除了有些设备有特殊的内存需求。
例如，三星的S5P多格式编解码设备需要位于不同内存池的缓存（这样允许从两个内存通道读取数据，从而增加内存带宽）。
此外，还有人想要分隔不同设备的内存分配，以限制CMA区域内的碎片。

CMA操作基于上下文环境。设备默认使用一个全局区域上下文，但是私有上下文同样可以被使用。
在struct devices和struct dma（即CMA上下文）之间有一个多对一的映射。意思是一个设备驱动会
有一些不同的struct device对象使用不止一个的CMA上下文，与此同时，多个struct device对象可以指向同一个CMA上下文。

指定一个CMA上下文给一个设备，唯一需要做的就是调用下面的方法：

```
int dma_declare_contiguous(struct device *dev, unsigned long size,
phys_addr_t base, phys_addr_t limit);
```

和dma_contiguous_reserve()一样，这个方法需要在memblock初始化完成之后，及大量内存被占用之前调用。
对于ARM平台，将其放在体系的reserve()回调方法中调用是个合适的地方。这不适合自动监测设备或那些载入的模块，
所以如果这些设备需要CMA上下文，还需要提供其他机制。

* 第一个参数是将要分派新上下文的设备。
* 第二个参数指定了预留区域的字节大小（不是页大小）。
* 第三个参数是区域的物理地址或置0。
* 最后一个参数和dma_contiguous_reserve()的limit参数意义一样。
* 返回值是0或者一个负的错误码。

可以声明一个有多少“私有”区域的限制，名字是CONFIG_CMA_AREAS。默认值是7，但是如果有需要，可以放心地增加它。

如果同一个非默认的CMA上下文需要被两个以上的设备使用，事情就变得有点复杂了。现存的API没有提供一种简明的方法去做这件事。
可以做的是使用dev_get_cma_area()方法得到设备使用的CMA区域，再使用dev_set_cma_area()将这个CMA上下文设置给另一个设备。
这个顺序不能早于postcore_initcall()阶段。如下是其工作方式：

```
static int __init foo_set_up_cma_areas(void)
{
  struct cma *cma;

  cma = dev_get_cma_area(device1);
  dev_set_cma_area(device2, cma);
  return 0;
}
postcore_initcall(foo_set_up_cma_areas);
```

事实上，由dma_contiguous_reserve()创建的默认上下文没有任何特殊的地方。
它不是必须的，系统没有它也能工作。如果没有默认的上下文，dma_alloc_from_contiguous()会对没有指定区域的设备返回NULL。
dev_get_cma_area()方法可以用于识别是这种情况还是申请失败。

dma_contiguous_reserve()方法没有大小的参数，那么它如何知道保留多少内存呢？有两个资源提供这些信息：

有一组Kconfig选项指定了保留的默认大小。所有这些选项位于

```
"Device Driver">>"Generic Driver Options">>"Contiguous Memory Allocator"
```

的Kconfig目录。它们允许从四个维度进行配置：以兆字节为单位的大小；总内存大小的百分比；两者的最小值；两者的最大值。默认大小是16MiBs。
还有一个cma=内核命令行选项。它允许在启动时指定该区域的大小而不用重新编译内核。该选项的单位是字节，并支持常用后缀。

## 那么它是如何工作的？

要理解CMA如何工作，需要了解一些迁移类型和页块的知识。

当从伙伴系统申请内存的时候，需要提供一个gfp_mask参数。不管其他事情，这个参数指定了要申请内存的迁移类型。
一个前一类型是MIGRATE_MOVABLE。它背后的意思是在可移动页面上的数据可以被迁移（或者移动，因此而命名），这对于磁盘缓存或者进程页面来说很有效。

为了使相同迁移类型的页面在一起，伙伴系统把页面组成“页面块”，每组都有一个指定的迁移类型。
分配器根据请求的类型在不同的页面块上分配页。如果尝试失败，分配器会在其它页面块上分配并
甚至修改页面块的迁移类型。这意味着一个不可移动的页可能分配自一个MIGRATE_MOVABLE页面块，
并导致该页面块的迁移类型改变。这不是CMA想要的，所以它引入了一个MIGRATE_CMA类型，
该类型又一个重要的属性：只有可移动页可以从MIGRATE_CMA页面块种分配。

那么，在启动期间，当dma_congiguous_reserve()和或者dma_declare_contiguous()方法被调用的时候，
CMA在memblock中预留一部分RAM，并在随后将其返还给伙伴系统，仅将其页面块的迁移类型置为MIGRATE_CMA。
最终的结果是所有预留的页都在伙伴系统里，所以它们都可以用于可移动页的分配。

在CMA分配的时候，dma_alloc_from_contiguous()选择一个页范围并调用：

```
int alloc_contig_range(unsigned long start, unsigned long end, unsigned migratetype);
```

start和end参数指定了目标内存的页框个数（或PFN范围）。最后一个参数migratetype指定了潜在的迁移类型；
在CMA的情况下，这个参数就是MIGRATE_CMA。这个函数所做的第一件事是将包含[start, end)范围内的
页面块标记为MIGRATE_ISOLATE。伙伴系统不会去触动这种类型的页面块。改变迁移类型不会魔法般地释放页面，
因此接下来需要调用__alloc_conting_migrate_range()。它扫描PFN范围并寻找可以迁移的页面。

迁移是将页面复制到系统其它内存部分并更新相关引用的过程。前一部份很直接，后面的部分需要内存管理子系统来完成。
当数据迁移完成，旧的页面被释放并回归伙伴系统。这就是为什么之前那些需要包含的页面块一定要标记为
MIGRATE_ISOLATE的原因。如果指定了其它的迁移类型，伙伴系统会毫不犹豫地将它们用于其它类型的申请。

现在所有alloc_contig_range关心的页都（希望如此）是空闲的了。该方法将从伙伴系统中取出它们，
并将这些页面块的类型改为MIGRATE_CMA。然后将这些页返回给调用者。

释放内存就更简单了。dma_release_from_contiguous()将其工作转交给：

```
void free_contig_range(unsigned long pfn, unsigned nr_pages);
```

这个函数迭代所有的页面并将其返还给伙伴系统。

结束语

CMA补丁自其第一个版本已经走过了很长一段路（甚至比它的先驱——三年前提出的物理内存管理都要长）。
这段旅程中，它虽然丢掉了一些功能，但是现在这样的确做得更好。在复杂的平台上，CMA还不能使用，但是将来会和ION以及dmabuf合并。
尽管现在是第23个版本了，CMA仍然不十分完美，像往常一样，仍然有很多地方可以去改进。希望它最终会合并进-mm分支，
在更多人的努力下创建一个让每个人都获益的解决方案。
