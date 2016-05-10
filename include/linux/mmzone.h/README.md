LINUX 物理内存管理
========================================

UMA vs NUMA
----------------------------------------

有两种类型计算机，分别以不同的方法管理物理内存:

* UMA

UMA计算机（一致内存访问，uniform memory ac-cess）将可用内存以连续方式组织起来（可能有小的缺口）。
SMP系统中的每个处理器访问各个内存区都是同样快。

* NUMA

NUMA计算机（非一致内存访问，non-uniformmemory access）总是多处理器计算机。系统的各个CPU
都有本地内存，可支持特别快速的访问。各个处理器之间通过总线连接起来，以支持对其他CPU的本地
内存的访问，当然比访问本地内存慢些。

* 区别

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/include/linux/mmzone.h/res/uma_numa.jpg

数据结构
----------------------------------------

Linux采用Node、Zone和Page三级结构来描述物理内存的.其关系如下所示:

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/include/linux/mmzone.h/res/node_zone_page.gif

Linux用一个pg_data_t(struct pglist_data)结构来描述系统的物理内存，系统中每个结点都挂接在一个
pgdat_list列表中，对UMA体系结构，则只有一个静态的pg_data_t结构contig_page_data。如下图所示:

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/include/linux/mmzone.h/res/relation.jpg

NODE_DATA:

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/include/linux/mmzone.h/NODE_DATA.md

### 结点

首先，内存划分为结点。每个结点关联到系统中的一个处理器，在内核中表示为pg_data_t的实例。

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/include/linux/mmzone.h/pg_data_t.md

### 内存域

各个结点又划分为内存域，是内存的进一步细分。

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/include/linux/mmzone.h/struct_zone.md
