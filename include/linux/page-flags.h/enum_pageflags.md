enum pageflags
========================================

comments
----------------------------------------

path: include/linux/page-flags.h
```
/*
 * Various page->flags bits:
 *
 * PG_reserved is set for special pages, which can never be swapped out. Some
 * of them might not even exist (eg empty_bad_page)...
 *
 * The PG_private bitflag is set on pagecache pages if they contain filesystem
 * specific data (which is normally at page->private). It can be used by
 * private allocations for its own usage.
 *
 * During initiation of disk I/O, PG_locked is set. This bit is set before I/O
 * and cleared when writeback _starts_ or when read _completes_. PG_writeback
 * is set before writeback starts and cleared when it finishes.
 *
 * PG_locked also pins a page in pagecache, and blocks truncation of the file
 * while it is held.
 *
 * page_waitqueue(page) is a wait queue of all tasks waiting for the page
 * to become unlocked.
 *
 * PG_uptodate tells whether the page's contents is valid.  When a read
 * completes, the page becomes uptodate, unless a disk I/O error happened.
 *
 * PG_referenced, PG_reclaim are used for page reclaim for anonymous and
 * file-backed pagecache (see mm/vmscan.c).
 *
 * PG_error is set to indicate that an I/O error occurred on this page.
 *
 * PG_arch_1 is an architecture specific page state bit.  The generic code
 * guarantees that this bit is cleared for a page when it first is entered into
 * the page cache.
 *
 * PG_highmem pages are not permanently mapped into the kernel virtual address
 * space, they need to be kmapped separately for doing IO on the pages.  The
 * struct page (these bits with information) are always mapped into kernel
 * address space...
 *
 * PG_hwpoison indicates that a page got corrupted in hardware and contains
 * data with incorrect ECC bits that triggered a machine check. Accessing is
 * not safe since it may cause another machine check. Don't touch!
 */

/*
 * Don't use the *_dontuse flags.  Use the macros.  Otherwise you'll break
 * locked- and dirty-page accounting.
 *
 * The page flags field is split into two parts, the main flags area
 * which extends from the low bits upwards, and the fields area which
 * extends from the high bits downwards.
 *
 *  | FIELD | ... | FLAGS |
 *  N-1           ^       0
 *               (NR_PAGEFLAGS)
 *
 * The fields area is reserved for fields mapping zone, node (for NUMA) and
 * SPARSEMEM section (for variants of SPARSEMEM that require section ids like
 * SPARSEMEM_EXTREME with !SPARSEMEM_VMEMMAP).
 */
```

PG_locked
----------------------------------------

```
enum pageflags {
    PG_locked,        /* Page is locked. Don't touch. */
```

PG_locked指定了页是否锁定。如果该比特位置位，内核的其他部分不允许访问该页。这防止了内存管理
出现竞态条件，例如，在从硬盘读取数据到页帧时。

PG_error
----------------------------------------

```
    PG_error,
```

PG_referenced
----------------------------------------

```
    PG_referenced,
```

PG_referenced控制了系统使用该页的活跃程度。在页交换子系统选择换出页时，该信息是很重要的.

PG_uptodate
----------------------------------------

```
    PG_uptodate,
```

PG_uptodate表示页的数据已经从块设备读取，其间没有出错。

PG_dirty
----------------------------------------

```
    PG_dirty,
```

如果与硬盘上的数据相比，页的内容已经改变，则置位PG_dirty。出于性能考虑，页并不在每次改变后
立即回写。因此内核使用该标志注明页已经改变，可以在稍后刷出。设置了该标志的页称为脏的
（通常，该意味着内存中的数据没有与外存储器介质如硬盘上的数据同步）。

PG_lru
----------------------------------------

```
    PG_lru,
```

PG_lru有助于实现页面回收和切换。内核使用两个最近最少使用（least recently used，lru）链表来
区别活动和不活动页。如果页在其中一个链表中，则设置该比特位。

PG_active
----------------------------------------

```
    PG_active,
```

还有一个PG_active标志，如果页在活动页链表中，则设置该标志。

PG_slab
----------------------------------------

```
    PG_slab,
```

如果页是slab分配器的一部分，则设置PG_slab位。

PG_owner_priv_1
----------------------------------------

```
    PG_owner_priv_1,    /* Owner use. If pagecache, fs may use*/
    PG_arch_1,
    PG_reserved,
```

PG_private
----------------------------------------

```
    PG_private,        /* If pagecache, has fs-private data */
    PG_private_2,        /* If pagecache, has fs aux data */
```

如果page结构的private成员非空，则必须设置PG_pri-vate位。用于I/O的页，可使用该字段将页
细分为多个缓冲区，但内核的其他部分也有各种不同的方法，将私有数据附加到页上。

PG_writeback
----------------------------------------

```
    PG_writeback,        /* Page is under writeback */
```

如果页的内容处于向块设备回写的过程中，则需要设置PG_writeback位。

PG_compound
----------------------------------------

```
#ifdef CONFIG_PAGEFLAGS_EXTENDED
    PG_head,        /* A head page */
    PG_tail,        /* A tail page */
#else
    PG_compound,        /* A compound page */
#endif
```

PG_compound表示该页属于一个更大的复合页，复合页由多个毗连的普通页组成。

PG_swapcache
----------------------------------------

```
    PG_swapcache,        /* Swap page: swp_entry_t in private */
```

如果页处于交换缓存，则设置PG_swapcache位。在这种情况下，private包含一个类型为swap_entry_t的项.

PG_mappedtodisk
----------------------------------------

```
    PG_mappedtodisk,    /* Has blocks allocated on-disk */
```

PG_reclaim
----------------------------------------

```
    PG_reclaim,        /* To be reclaimed asap */
```

在可用内存的数量变少时，内核试图周期性地回收页，即剔除不活动、未用的页。内核决定回收某个特定
的页之后，需要设置PG_reclaim标志通知.

PG_swapbacked
----------------------------------------

```
    PG_swapbacked,        /* Page is backed by RAM/swap */
    PG_unevictable,        /* Page is "unevictable"  */
#ifdef CONFIG_MMU
    PG_mlocked,        /* Page is vma mlocked */
#endif
#ifdef CONFIG_ARCH_USES_PG_UNCACHED
    PG_uncached,        /* Page has been mapped as uncached */
#endif
#ifdef CONFIG_MEMORY_FAILURE
    PG_hwpoison,        /* hardware poisoned page. Don't touch */
#endif
#ifdef CONFIG_TRANSPARENT_HUGEPAGE
    PG_compound_lock,
#endif
#if defined(CONFIG_IDLE_PAGE_TRACKING) && defined(CONFIG_64BIT)
    PG_young,
    PG_idle,
#endif
    __NR_PAGEFLAGS,

    /* Filesystems */
    PG_checked = PG_owner_priv_1,

    /* Two page bits are conscripted by FS-Cache to maintain local caching
     * state.  These bits are set on pages belonging to the netfs's inodes
     * when those inodes are being locally cached.
     */
    PG_fscache = PG_private_2,    /* page backed by cache */

    /* XEN */
    /* Pinned in Xen as a read-only pagetable page. */
    PG_pinned = PG_owner_priv_1,
    /* Pinned as part of domain save (see xen_mm_pin_all()). */
    PG_savepinned = PG_dirty,
    /* Has a grant mapping of another (foreign) domain's page. */
    PG_foreign = PG_owner_priv_1,

    /* SLOB */
    PG_slob_free = PG_private,
};
```

MACROS
----------------------------------------

内核定义了一些标准宏，用于检查页是否设置了某个特定的比特位，或者操作某个比特位。这些宏的名称
有一定的模式，如下所述:

* PageXXX(page)会检查页是否设置了PG_XXX位。例如，PageDirty检查PG_dirty位，
  而PageActive检查PG_active位，等等。
* SetPageXXX在某个比特位没有设置的情况下，设置该比特位，并返回原值。
* ClearPageXXX无条件地清除某个特定的比特位。
* TestClearPageXXX清除某个设置的比特位，并返回原值。

**注意**: 这些操作的实现是原子的。

辅助函数
----------------------------------------

很多情况下，需要等待页的状态改变，然后才能恢复工作。内核提供了两个辅助函数，对此很有用处：

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/pagemap.h/wait_on_page_xxx.md
