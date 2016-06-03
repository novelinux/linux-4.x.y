Slab
========================================

Linux 所使用的 slab 分配器的基础是 Jeff Bonwick 为 SunOS 操作系统首次引入的一种算法。Jeff
的分配器是围绕对象缓存进行的。在内核中，会为有限的对象集（例如文件描述符和其他常见结构）分配
大量内存。Jeff 发现对内核中普通对象进行初始化所需的时间超过了对其进行分配和释放所需的时间。
因此他的结论是不应该将内存释放回一个全局的内存池，而是将内存保持为针对特定目的而初始化的状态。
例如，如果内存被分配给了一个互斥锁，那么只需在为互斥锁首次分配内存时执行一次互斥锁初始化函数
（mutex_init）即可。后续的内存分配不需要执行这个初始化函数，因为从上次释放和调用析构之后，
它已经处于所需的状态中了。

Linux slab 分配器使用了这种思想和其他一些思想来构建一个在空间和时间上都具有高效性的内存分配器。

每个C程序员都熟悉malloc，及其在C标准库中的相关函数。大多数程序分配若干字节内存时，经常会调用
这些函数。

内核也必须经常分配内存，但无法借助于标准库的函数。上面描述的伙伴系统支持按页分配内存，
但这个单位太大了。如果需要为一个10个字符的字符串分配空间，分配一个4 KiB或更多空间的完整页面，
不仅浪费而且完全不可接受。显然的解决方案是将页拆分为更小的单位，可以容纳大量的小对象。

为此必须引入新的管理机制，这会给内核带来更大的开销。为最小化这个额外负担对系统性能的影响，该管理层
的实现应该尽可能紧凑，以便不要对处理器的高速缓存和TLB带来显著影响。同时，内核还必须保证内存利用
的速度和效率。不仅Linux，而且类似的UNIX和所有其他的操作系统，都需要面对这个问题。经过一定的时间，
已经提出了一些或好或坏的解决方案，在一般的操作系统文献中都有讲解。此类提议之一，所谓slab分配，
证明对许多种类工作负荷都非常高效。提供小内存块不是slab分配器的唯一任务。由于结构上的特点，它也用
作一个缓存，主要针对经常分配并释放的对象。通过建立slab缓存，内核能够储备一些对象，供后续使用，
即使在初始化状态，也是如此。

举例来说，为管理与进程关联的文件系统数据，内核必须经常生成struct fs_struct的新实例。此类型实例
占据的内存块同样需要经常回收（在进程结束时）。换句话说，内核趋向于非常有规律地分配并释放大小为
sizeof{fs_struct}的内存块。slab分配器将释放的内存块保存在一个内部列表中，并不马上返回给伙伴系统。
在请求为该类对象分配一个新实例时，会使用最近释放的内存块。这有两个优点。首先，由于内核不必使用
伙伴系统算法，处理时间会变短。其次，由于该内存块仍然是“新”的，因此其仍然驻留在CPU高速缓存的
概率较高。

slab分配器还有两个好处:

* 调用伙伴系统的操作对系统的数据和指令高速缓存有相当的影响。内核越浪费这些资源，这些资源对
用户空间进程就越不可用。更轻量级的slab分配器在可能的情况下减少了对伙伴系统的调用，有助于防止
不受欢迎的缓存“污染”。

* 如果数据存储在伙伴系统直接提供的页中，那么其地址总是出现在2的幂次的整数倍附近(许多将页划分为
更小块的其他分配方法，也有同样的特征）。这对CPU高速缓存的利用有负面影响，由于这种地址分布，
使得某些缓存行过度使用，而其他的则几乎为空。多处理器系统可能会加剧这种不利情况，因为不同的内存
地址可能在不同的总线上传输，上述情况会导致某些总线拥塞，而其他总线则几乎没有使用。通过slab着色
（slab coloring），slab分配器能够均匀地分布对象，以实现均匀的缓存利用，如下所示。

经常使用的内核对象保存在CPU高速缓存中，这是我们想要的效果。前文的注释提到，从slab分配器的角度
进行衡量，伙伴系统的高速缓存和TLB占用较大，这是一个负面效应。因为这会导致不重要的数据驻留在
CPU高速缓存中，而重要的数据则被置换到内存，显然应该防止这种情况出现。着色这个术语是隐喻性的。
它与颜色无关，只是表示slab中的对象需要移动的特定偏移量，以便使对象放置到不同的缓存行。
slab分配器由何得名？各个缓存管理的对象，会合并为较大的组，覆盖一个或多个连续页帧。
这种组称作slab，每个缓存由几个这种slab组成。


备选分配器
----------------------------------------

尽管slab分配器对许多可能的工作负荷都工作良好，但也有一些情形，它无法提供最优性能。如果某些计算机
处于当前硬件尺度的边界上，在此类计算机上使用slab分配会出现一些问题：微小的嵌入式系统，配备有大量
物理内存的大规模并行系统。

在第二种情况下，slab分配器所需的大量元数据可能成为一个问题：开发者称，在大型系统上仅slab的
数据结构就需要很多GiB内存。对嵌入式系统来说，slab分配器代码量和复杂性都太高。为处理此类情形，
在内核版本2.6开发期间，增加了slab分配器的两个替代品:

* slob

分配器进行了特别优化，以便减少代码量。它围绕一个简单的内存块链表展开（因此而得名）。
在分配内存时，使用了同样简单的最先适配算法。slob分配器只有大约600行代码，总的代码量很小。
事实上，从速度来说，它不是最高效的分配器，也肯定不是为大型系统设计的。

* slub

分配器通过将页帧打包为组，并通过struct page中未使用的字段来管理这些组，试图最小化所需的内存开销。
这样做不会简化该结构的定义，但在大型计算机上slub比slab提供了更好的性能，说明了这样做是正确的。

Principle
----------------------------------------

slab分配器由一个紧密地交织的数据和内存结构的网络组成，初看起来不容易理解其运作方式。因此在
考察其实现之前，重要的是获得各个结构之间关系的概观。基本上，slab缓存由下图所示的两部分组成：
保存管理性数据的缓存对象和保存被管理对象的各个slab。

https://github.com/novelinux/linux-4.x.y/tree/master/mm/slab.c/res/slab-principle.jpg

每个缓存只负责一种对象类型（例如struct unix_sock实例），或提供一般性的缓冲区。各个缓存中slab
的数目各有不同，这与已经使用的页的数目、对象长度和被管理对象的数目有关。

另外，系统中所有的缓存都保存在一个双链表slab_caches中。这使得内核有机会依次遍历所有的缓存。
这是有必要的，例如在即将发生内存不足时，内核可能需要缩减分配给缓存的内存数量。

下图给出了 slab 结构的高层组织结构。在最高层是 cache_chain(slab_caches)，这是一个slab缓存的
链接列表。这对于best-fit 算法非常有用，可以用来查找最适合所需要的分配大小的缓存（遍历列表）。
cache_chain 的每个元素都是一个 kmem_cache 结构的引用（称为一个 cache）。它定义了一个要管理的
给定大小的对象池。

```
  slab_caches
      $
struct kmem_cache                            +-> slabs_partial -> page -+-> object
      $                                      |                          |
struct kmem_cache -> struct kmem_cache_node -+-> slabs_full    -> page -+-> object
      $                                      |                          |
struct kmem_cache                            +-> slabs_free    -> page -+-> object
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/slab.c/res/slab.jpg

Data Structure
----------------------------------------

### slab_caches

https://github.com/novelinux/linux-4.x.y/tree/master/mm/slab_common.c/slab_caches.md

### struct kmem_cache

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/slab_def.h/struct_kmem_cache.md

### struct array_cache

https://github.com/novelinux/linux-4.x.y/tree/master/mm/slab.c/struct_array_cache.md

### struct kmem_cache_node

https://github.com/novelinux/linux-4.x.y/tree/master/mm/slab.h/struct_kmem_cache_node.md

### struct page

https://github.com/novelinux/linux-4.x.y/blob/master/include/linux/mm_types.h/struct_page.md

Initialization
----------------------------------------

https://github.com/novelinux/linux-4.x.y/blob/master/mm/slab.c/kmem_cache_init.md

APIS
----------------------------------------

### kmem_cache_alloc

```
kmem_cache_alloc
 |
 +-> slab_alloc
     |
     +-> __do_cache_alloc
         |
         +-> ____cache_alloc
             |
             +-> cpu_cache_get -> ac_get_obj -> __ac_get_obj
             |
             +-> cache_alloc_refill
                 |
                 +-> cpu_cache_get
                 |
                 +-> slab_get_obj
                 |
                 +-> ac_put_obj
```

https://github.com/novelinux/linux-4.x.y/blob/master/mm/slab.c/kmem_cache_alloc.md

### kmalloc(size, flags)

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/slab.h/kmalloc.md

### kfree(*ptr)

slabinfo
----------------------------------------

所有活动缓存的列表保存在/proc/slabinfo中:

```
root@android:/ # cat /proc/slabinfo
slabinfo - version: 2.1
# name            <active_objs> <num_objs> <objsize> <objperslab> <pagesperslab> : tunables <limit> <batchcount> <sharedfactor> : slabdata <active_slabs> <num_slabs> <sharedavail>
ext4_groupinfo_4k     39     39    104   39    1 : tunables    0    0    0 : slabdata      1      1      0
UDPLITEv6              0      0    768   21    4 : tunables    0    0    0 : slabdata      0      0      0
UDPv6                  0      0    768   21    4 : tunables    0    0    0 : slabdata      0      0      0
tw_sock_TCPv6          0      0    192   21    1 : tunables    0    0    0 : slabdata      0      0      0
TCPv6                  0      0   1472   22    8 : tunables    0    0    0 : slabdata      0      0      0
nf_conntrack_expect      0      0    176   23    1 : tunables    0    0    0 : slabdata      0      0      0
nf_conntrack_c1809980      0      0    256   16    1 : tunables    0    0    0 : slabdata      0      0      0
ashmem_area_cache      0      0    296   27    2 : tunables    0    0    0 : slabdata      0      0      0
dm_crypt_io            0      0    104   39    1 : tunables    0    0    0 : slabdata      0      0      0
kcopyd_job             0      0   2808   11    8 : tunables    0    0    0 : slabdata      0      0      0
...
```