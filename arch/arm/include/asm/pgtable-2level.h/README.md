Linux arm page table
========================================

分段可以给每个进程分配不同的线性地址空间，分页可以把同一线性地址空间映射到不同的物理空间。
与分段相比，Linux更喜欢分页方式，因为：

* 当所有进程使用相同的段寄存器值时，内存管理变得更简单，也就是说它们能共享同样的一簇线性地址。
* 为了兼容绝大多数的CPU，RISC体系架构对分段的支持很有限，比如ARM架构的CPU中的MMU单元通常只
  支持分页，而不支持分段。

分页使得不同的虚拟内存页可以转入同一物理页框。于此同时分页机制可以实现对每个页面的访问控制，
这是在平衡内存使用效率和地址转换效率之间做出的选择。如果4G的虚拟空间，每一个字节都要使用一个
数据结构来记录它的访问控制信息，那么显然是不可能的。如果把4G的虚拟空间以4K(为什么是4K大小？
这是由于Linux中的可执行文件中的代码段和数据段等都是相对于4K对齐的)大小分割成若干个不同的页面，
那么每个页面需要一个数据结构进行控制，只需要1M的内存来存储。但是由于每一个用户进程都有自己的
独立空间，所以每一个进程都需要一个1M的内存来存储页表信息，这依然是对系统内存的浪费，采用两级
甚至多级分页是一种不错的解决方案。另外有些处理器采用64位体系架构，此时两级也不合适了，所以
Linux使用三级页表。

Linux page table
----------------------------------------

https://github.com/leeminghao/doc-linux/blob/master/4.x.y//mm/misc/page_table.md

Linux arm page table
----------------------------------------

path: arch/arm/include/asm/pgtable-2level.h

Hardware-wise, we have a two level page table structure, where the first
level has 4096 entries, and the second level has 256 entries.  Each entry
is one 32-bit word.  Most of the bits in the second level entry are used
by hardware, and there aren't any "accessed" and "dirty" bits.

Linux on the other hand has a three level page table structure, which can
be wrapped to fit a two level page table structure easily - using the PGD
and PTE only.  However, Linux also expects one "PTE" table per page, and
at least a "dirty" bit.

Therefore, we tweak the implementation slightly - we tell Linux that we
have 2048 entries in the first level, each of which is 8 bytes (iow, two
hardware pointers to the second level.)  The second level contains two
hardware PTE tables arranged contiguously, preceded by Linux versions
which contain the state information Linux needs.  We, therefore, end up
with 512 entries in the "PTE" level.

This leads to the page tables having the following layout:

```
   pgd             pte
|        |
+--------+
|        |       +------------+ +0
+- - - - +       | Linux pt 0 |
|        |       +------------+ +1024
+--------+ +0    | Linux pt 1 |
|        |-----> +------------+ +2048
+- - - - + +4    |  h/w pt 0  |
|        |-----> +------------+ +3072
+--------+ +8    |  h/w pt 1  |
|        |       +------------+ +4096
```

See L_PTE_xxx below for definitions of bits in the "Linux pt", and
PTE_xxx for definitions of bits appearing in the "h/w pt".

PMD_xxx definitions refer to bits in the first level page table.

The "dirty" bit is emulated by only granting hardware write permission
iff the page is marked "writable" and "dirty" in the Linux PTE.  This
means that a write to a clean page will cause a permission fault, and
the Linux MM layer will mark the page dirty via handle_pte_fault().
For the hardware to notice the permission change, the TLB entry must
be flushed, and ptep_set_access_flags() does that for us.

The "accessed" or "young" bit is emulated by a similar method; we only
allow accesses to the page if the "young" bit is set.  Accesses to the
page will cause a fault, and handle_pte_fault() will set the young bit
for us as long as the page is marked present in the corresponding Linux
PTE entry.  Again, ptep_set_access_flags() will ensure that the TLB is
up to date.

However, when the "young" bit is cleared, we deny access to the page
by clearing the hardware PTE.  Currently Linux does not flush the TLB
for us in this case, which means the TLB will retain the transation
until either the TLB entry is evicted under pressure, or a context
switch which changes the user space mapping occurs.

Linux支持三级页表，作为其默认的页表结构。ARM是两级页表, PGD和PTE。从上面可以可以
看出一个work around的实现。PGD和PTE并不是直接对应ARM硬件的页表目录项。而是做了一些
为了linux上层的要求的一个方案。首先，他把4096个pgd项变成2048个，物理上还是一个pgd
指向一个256个pte项的数组的，这没办法改。但是pgd指针逻辑上合并成一个，各自指向的pte
数组也合并,并且是连续的。这512个pte项合并起来，这个pte分配的页（一般linux需要一个pte表
在一个页里，代码注释也写了）还剩下一半的内容，刚好可以存放arm不支持的一些标记(Linux pt 0, 1),
而这些标记是linux必须的，比如dirty。这个方案还非常具有可扩展性，不依赖arm本身的标记。
dirty标记的实现是通过对arm支持的权限fault的中断来写这个标记,这样方式是相当于一种模拟。

页表表示
----------------------------------------

* pgd:
  页全局目录(Page Global Directory)，是多级页表的抽象最高层。每一级的页表都处理不同大小
  的内存。每项都指向一个更小目录的低级表，因此pgd就是一个页表目录。当代码遍历这个结构时
  （有些驱动程序就要这样做），就称为是在遍历页表。

* pmd:
  页中间目录 (Page Middle Directory),即pmd，是页表的中间层。在 x86 架构上，pmd 在硬件中
  并不存在，但是在内核代码中它是与pgd合并在一起的。

* pte:
  页表条目 (Page Table Entry)，是页表的最低层，它直接处理页，该值包含某页的物理地址，还包含了
  说明该条目是否有效及相关页是否在物理内存中的位。

```
typedef u32 pteval_t;
typedef u32 pmdval_t;

#undef STRICT_MM_TYPECHECKS

#ifdef STRICT_MM_TYPECHECKS

/*
 * These are used to make use of C type-checking..
 */
typedef struct { pteval_t pte; } pte_t;
typedef struct { pmdval_t pmd; } pmd_t;
typedef struct { pmdval_t pgd[2]; } pgd_t;
typedef struct { pteval_t pgprot; } pgprot_t;

#define pte_val(x)      ((x).pte)
#define pmd_val(x)      ((x).pmd)
#define pgd_val(x)	((x).pgd[0])
#define pgprot_val(x)   ((x).pgprot)

#define __pte(x)        ((pte_t) { (x) } )
#define __pmd(x)        ((pmd_t) { (x) } )
#define __pgprot(x)     ((pgprot_t) { (x) } )
```
