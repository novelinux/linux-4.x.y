Buddy - Physical Memory
========================================

在内核初始化完成后，内存管理的责任由伙伴系统承担。伙伴系统基于一种相对简单然而令人吃惊的
强大算法，已经伴随我们几乎40年。它结合了优秀内存分配器的两个关键特征：速度和效率。

Data Structures
----------------------------------------

系统内存中的每个物理内存页（页帧），都对应于一个struct page实例。每个内存域都关联了一个
struct zone的实例，其中保存了用于管理伙伴数据的主要数组struct free_area.

### struct zone

https://github.com/novelinux/linux-4.x.y/blob/master/include/linux/mmzone.h/struct_zone.md

### struct free_area

https://github.com/novelinux/linux-4.x.y/blob/master/include/linux/mmzone.h/struct_free_area.md

#### zone_init_free_lists

free_area的初始化由函数来完成:

https://github.com/novelinux/linux-4.x.y/blob/master/mm/page_alloc.c/zone_init_free_lists.md


伙伴不必是彼此连接的,如果一个内存区在分配其间分解为两半,内核会自动将未用的一半加入到对应的链表中。
如果在未来的某个时刻，由于内存释放的缘故，两个内存区都处于空闲状态，可通过其地址判断其是否为伙伴。
管理工作较少，是伙伴系统的一个主要优点。
基于伙伴系统的内存管理专注于某个结点的某个内存域，例如，DMA或高端内存域。但所有内存域和结点的
伙伴系统都通过备用分配列表连接起来。下图说明了这种关系:

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/mmzone.h/res/buddy_backup.jpg

在首选的内存域或节点无法满足内存分配请求时，首先尝试同一结点的另一个内存域，接下来再尝试
另一个结点，直至满足请求。

buddyinfo
----------------------------------------

有关伙伴系统当前状态的信息可以在/proc/buddyinfo中获得：

```
root@aries:/ # cat /proc/buddyinfo
Node 0, zone   Normal   3847   2378    917    485    206     92     50      0      0      0      0
Node 0, zone  HighMem   1894    409     20     12     20      0      0      0      0      0      0
```

上述输出给出了各个内存域中每个分配阶中空闲项的数目，从左至右，阶依次升高。

产生碎片
----------------------------------------

伙伴系统的基本原理已经讨论过，其方案在最近几年间确实工作得非常好。但在Linux内存管理方面，
有一个长期存在的问题：在系统启动并长期运行后，物理内存会产生很多碎片。该情形如下图所示:

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/mmzone.h/res/fragmentation1.jpg

假定内存由60页组成，左侧的地址空间中散布着空闲页。尽管大约25%的物理内存仍然未分配，但最大的
连续空闲区只有一页。这对用户空间应用程序没有问题：其内存是通过页表映射的，无论空闲页在物理内存
中的分布如何，应用程序看到的内存似乎总是连续的。右图给出的情形中，空闲页和使用页的数目与左图相同，
但所有空闲页都位于一个连续区中。
但对内核来说，碎片是一个问题。由于(大多数)物理内存一致映射到地址空间的内核部分，那么在左图的场景
中，无法映射比一页更大的内存区。尽管许多时候内核都分配的是比较小的内存，但也有时候需要分配多于一页
的内存。显而易见，在分配较大内存的情况下，右图中所有已分配页和空闲页都处于连续内存区的情形，是更为
可取的。很有趣的一点是，在大部分内存仍然未分配时，就也可能发生碎片问题。考虑如下图所示的情形:

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/mmzone.h/res/fragmentation2.jpg

只分配了4页，但可分配的最大连续区只有8页，因为伙伴系统所能工作的分配范围只能是2的幂次。

上述内存碎片只涉及内核，这只是部分正确的。大多数现代CPU都提供了使用巨型页的可能性，比普通页大得多。
这对内存使用密集的应用程序有好处。在使用更大的页时，地址转换后备缓冲器只需处理较少的项，降低了
TLB缓存失效的可能性。但分配巨型页需要连续的空闲物理内存！很长时间以来，物理内存的碎片确实是Linux
的弱点之一。尽管已经提出了许多方法，但没有哪个方法能够既满足Linux需要处理的各种类型工作负荷提出的
苛刻需求，同时又对其他事务影响不大。

避免碎片
----------------------------------------

### 对可移动页进行分组

在内核2.6.24开发期间，防止碎片的方法最终加入内核。在讨论具体策略之前，有一点需要澄清。文件系统也有
碎片，该领域的碎片问题主要通过碎片合并工具解决。它们分析文件系统，重新排序已分配存储块，从而建立
较大的连续存储区。理论上，该方法对物理内存也是可能的，但由于许多物理内存页不能移动到任意位置，阻碍
了该方法的实施。因此，内核的方法是反碎片(anti-fragmentation)，即试图从最初开始尽可能防止碎片。

内核将已分配页划分为如下几种不同类型:

https://github.com/novelinux/linux-4.x.y/blob/master/include/linux/mmzone.h/MIGRATE_TYPES.md

页的可移动性，依赖该页属于上述种类别的哪一种。内核使用的反碎片技术，即基于将具有相同可移动性的
页分组的思想。为什么这种方法有助于减少碎片？回想图fragmentation2,由于页无法移动，导致在原本几乎
全空的内存区中无法进行连续分配。根据页的可移动性，将其分配到不同的列表中，即可防止这种情形。例如，
不可移动的页不能位于可移动内存区的中间，否则就无法从该内存区分配较大的连续内存块。图fragmentation2
中大多数空闲页都属于可回收的类别，而分配的页则是不可移动的。如果这些页聚集到两个不同的列表中，
如下图所示：

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/mmzone.h/res/fragmentation3.jpg

在不可移动页中仍然难以找到较大的连续空闲空间，但对可回收的页，就容易多了。
但要注意，从最初开始，内存并未划分为可移动性不同的区。这些是在运行时形成的。内核的另一种方法确实
将内存分区，分别用于可移动页和不可移动页的分配。但这种划分对这里描述的方法是不必要的。

#### pagetypeinfo

在各个迁移页链表之间，当前的页面分配状态可以从/proc/pagetypeinfo获得：

```
root@aries:/ # cat /proc/pagetypeinfo
Page block order: 10
Pages per block:  1024

Free pages count per migrate type at order       0      1      2      3      4      5      6      7      8      9     10
Node    0, zone   Normal, type    Unmovable    303    226    188    104      9      8      5      5      3      0      0
Node    0, zone   Normal, type  Reclaimable     37     34     29      8      1      1      1      0      0      0      0
Node    0, zone   Normal, type      Movable   1563   1327    543    319    199     97     56      5      0      0      0
Node    0, zone   Normal, type      Reserve      0      0      0      0      0      0      0      0      0      0      0
Node    0, zone   Normal, type          CMA    899    951    266     67     18      1      1      0      0      0      0
Node    0, zone   Normal, type      Isolate      0      0      0      0      0      0      0      0      0      0      0
Node    0, zone  HighMem, type    Unmovable      1      1      4      8      1      0      0      0      0      0      0
Node    0, zone  HighMem, type  Reclaimable      0      0      0      0      0      0      0      0      0      0      0
Node    0, zone  HighMem, type      Movable   1430    731    182     21     13      0      0      0      0      0      0
Node    0, zone  HighMem, type      Reserve     45     22     10      3      0      0      0      0      0      0      0
Node    0, zone  HighMem, type          CMA      0      0      0      0      0      0      0      0      0      0      0
Node    0, zone  HighMem, type      Isolate      0      0      0      0      0      0      0      0      0      0      0

Number of blocks type     Unmovable  Reclaimable      Movable      Reserve          CMA      Isolate
Node 0, zone   Normal           44           10           99            1           26            0
Node 0, zone  HighMem            7            0          311            1            0            0
```

在分配内存时，如果必须“盗取”不同于预定迁移类型的内存区，内核在策略上倾向于“盗取”更大的内存区。
由于所有页最初都是可移动的，那么在内核分配不可移动的内存区时，则必须“盗取”。实际上，在启动期间
分配可移动内存区的情况较少，那么分配器有很高的几率分配长度最大的内存区，并将其从可移动列表转换
到不可移动列表。由于分配的内存区长度是最大的，因此不会向可移动内存中引入碎片。总而言之，这种做法
避免了启动期间内核分配的内存（经常在系统的整个运行时间都不释放）散布到物理内存各处，从而使其他
类型的内存分配免受碎片的干扰，这也是页可移动性分组框架的最重要的目标之一。

### 可移动内存域

依据可移动性组织页是防止物理内存碎片的一种可能方法，内核还提供了另一种阻止该问题的手段：
虚拟内存域ZONE_MOVABLE。该机制在内核2.6.23开发期间已经并入内核，比可移动性分组框架加入内核早一个
版本。与可移动性分组相反，ZONE_MOVABLE特性必须由管理员显式激活。

基本思想很简单：可用的物理内存划分为两个内存域，一个用于可移动分配，一个用于不可移动分配。这会自动
防止不可移动页向可移动内存域引入碎片。

这马上引出了另一个问题：内核如何在两个竞争的内存域之间分配可用的内存？这显然对内核要求太高，
因此系统管理员必须作出决定。毕竟，人可以更好地预测计算机需要处理的场景，以及各种类型内存分配的
预期分布。

kernelcore参数用来指定用于不可移动分配的内存数量，即用于既不能回收也不能迁移的内存数量。剩余的
内存用于可移动分配。在分析该参数之后，结果保存在全局变量required_kernelcore中。还可以使用参数
movablecore控制用于可移动内存分配的内存数量。required_kernelcore的大小将会据此计算。如果有些
聪明人同时指定两个参数，内核会按前述方法计算出required_kernelcore的值，并取指定值和计算值中较大
的一个。取决于体系结构和内核配置，ZONE_MOVABLE内存域可能位于高端或普通内存域：

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/mmzone.h/enum_zone_type.md

辅助函数find_zone_movable_pfns_for_nodes用于计算进入ZONE_MOVABLE的内存数量。如果kernelcore和
movablecore参数都没有指定，find_zone_movable_pfns_for_nodes会使ZONE_MOVABLE保持为空，该机制
处于无效状态。谈到从物理内存域提取多少内存用于ZONE_MOVABLE的问题，必须考虑下面两种情况。

* 用于不可移动分配的内存会平均地分布到所有内存结点上。
* 只使用来自最高内存域的内存。在内存较多的32位系统上，这通常会是ZONE_HIGHMEM，但是对于64位系统，
  将使用ZONE_NORMAL或ZONE_DMA32。
* 用于为虚拟内存域ZONE_MOVABLE提取内存页的物理内存域，保存在全局变量movable_zone中；
* 对每个结点来说，zone_movable_pfn[node_id]表示ZONE_MOVABLE在movable_zone内存域中所取得内存的
  起始地址。

Memblock ==> Buddy
----------------------------------------

在内存启动过程期间，Linux系统采用Memblock算法来管理系统物理内存, 在初始化完成之后，需要将
Memblock切换成Buddy来接管相应的工作.具体接管过程如下所示:

```
 mm_init
   |
mem_init
   |
   +--> free_all_bootmem
   |          |
   |          +--> reset_all_zones_managed_pages
   |          |
   |          +--> free_low_memory_core_early
   |                         |
   |                 __free_memory_core
   |                         |
   |                __free_pages_memory
   |                         |
   |                __free_pages_bootmem
   |                         |
   |               __free_pages_boot_core
   |                         |
   |                   __free_pages
   +--> free_highpages
```

### mm_init

https://github.com/novelinux/linux-4.x.y/tree/master/init/main.c/mm_init.md

APIS
----------------------------------------

就伙伴系统的接口而言，NUMA或UMA体系结构是没有差别的，二者的调用语法都是相同的。所有函数的一个
共同点是：只能分配2的整数幂个页。因此，接口中不像C标准库的malloc函数或memblock分配器那样指定了
所需内存大小作为参数。相反，必须指定的是分配阶，伙伴系统将在内存中分配2^order页。内核中细粒度的
分配只能借助于slab分配器（或者slub、slob分配器），后者基于伙伴系统.

### Allocation Macros

#### alloc_pages(mask, order)

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/gfp.h/alloc_pages.md

分配2页并返回一个struct page的实例，表示分配的内存块的起始页。
alloc_page(mask)是前者在order = 0情况下的简化形式，只分配一页。

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/gfp.h/alloc_page.md

在空闲内存无法满足请求以至于分配失败的情况下，函数都返回空指针

#### get_zeroed_page(mask)

分配一页并返回一个page实例，页对应的内存填充0(所有其他函数，分配之后页的内容是未定义的)。
在空闲内存无法满足请求以至于分配失败的情况下，函数都返回0

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/get_zeroed_page.md

#### __get_free_pages(mask, order)

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/__get_free_pages.md

其的工作方式与上述函数相同，但返回分配内存块的虚拟地址，而不是page实例。
__get_free_page(mask)是前者在order = 0情况下的简化形式，只分配一页。

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/gfp.h/__get_free_page.md

在空闲内存无法满足请求以至于分配失败的情况下，函数都返回0

#### get_dma_pages(gfp_mask, order)

用来获得适用于DMA的页。

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/gfp.h/get_dma_pages.md

以上内存分配各函数关系:

```
alloc_page    get_zeroed_page    __get_free_page    __get_dma_pages
   |                 |                  |                 |
   |                 +------------------+-----------------+
   |                                    |
   |                             __get_free_pages
   |                                    |
   +----------->alloc_pages<------------+
                     |
              alloc_pages_node
                     |
             __alloc_pages_node
                     |
               __alloc_pages
                     |
           __alloc_pages_nodemask
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/__alloc_pages_nodemask.md

### Free Macros

#### __free_pages(struct page *,order)

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/__free_pages.md

用于将一个或2^order页返回给内存管理子系统,内存区的起始地址由指向该内存区的第一个page
实例的指针表示.

#### free_pages(addr, order)

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/free_pages.md

这两个函数的语义类似于前两个函数，但在表示需要释放的内存区时，使用了虚拟内存地址而不是page实例

以上内存释放函数关系:

```
__free_page    free_page
     |             |
     |         free_pages
     |             |
     +------+------+
            |
      __free_pages
```

内核在各次分配之后都必须检查返回的结果。这种惯例与设计得很好的用户层应用程序没什么不同，
但在内核中忽略检查会导致严重得多的故障。内核除了伙伴系统函数之外，还提供了其他内存管理函数。
它们以伙伴系统为基础，但并不属于伙伴分配器自身。这些函数包括vmalloc和vmalloc_32，使用页表
将不连续的内存映射到内核地址空间中，使之看上去是连续的。还有一组kmalloc类型的函数，用于
分配小于一整页的内存区。

### Allocation Mask

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/gfp.h/README.md
