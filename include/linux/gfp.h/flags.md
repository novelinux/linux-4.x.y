GFP Flags
========================================

__GFP_WAIT
----------------------------------------

path: include/linux/gfp.h
```
#define ___GFP_WAIT         0x10u
...
#define __GFP_WAIT  ((__force gfp_t)___GFP_WAIT)  /* Can wait and reschedule? */
```

__GFP_WAIT表示分配内存的请求可以中断。也就是说，调度器在该请求期间可随意选择另一个过程执行，
或者该请求可以被另一个更重要的事件中断。分配器还可以在返回内存之前，在队列上等待一个事件
（相关进程会进入睡眠状态）。

__GFP_HIGH
----------------------------------------

```
#define ___GFP_HIGH         0x20u
...
#define __GFP_HIGH  ((__force gfp_t)___GFP_HIGH)  /* Should access emergency pools? */
```

如果请求非常重要，则设置__GFP_HIGH，即内核急切地需要内存时。在分配内存失败可能给内核带来严重
后果时（比如威胁到系统稳定性或系统崩溃），总是会使用该标志。虽然名字相似，但__GFP_HIGH与
__GFP_HIGHMEM毫无关系，请不要弄混这两者。

__GFP_IO
----------------------------------------

```
#define ___GFP_IO           0x40u
...
#define __GFP_IO    ((__force gfp_t)___GFP_IO)    /* Can start physical IO? */
```

__GFP_IO说明在查找空闲内存期间内核可以进行I/O操作。实际上，这意味着如果内核在内存分配期间换出页，
那么仅当设置该标志时，才能将选择的页写入硬盘。

__GFP_FS
----------------------------------------

```
#define ___GFP_FS           0x80u
...
#define __GFP_FS    ((__force gfp_t)___GFP_FS)    /* Can call down to low-level FS? */
```

__GFP_FS允许内核执行VFS操作。在与VFS层有联系的内核子系统中必须禁用，因为这可能引起循环递归调用。

__GFP_COLD
----------------------------------------

```
#define ___GFP_COLD         0x100u
...
#define __GFP_COLD    ((__force gfp_t)___GFP_COLD)    /* Cache-cold page required */
```

如果需要分配不在CPU高速缓存中的“冷”页时，则设置__GFP_COLD。

__GFP_NOWARN
----------------------------------------

```
#define ___GFP_NOWARN       0x200u
...
#define __GFP_NOWARN ((__force gfp_t)___GFP_NOWARN)  /* Suppress page allocation failure warning */
```

__GFP_NOWARN在分配失败时禁止内核故障警告。在极少数场合该标志有用。

__GFP_REPEAT
----------------------------------------

```
/* __GFP_REPEAT: Try hard to allocate the memory, but the allocation attempt
 * _might_ fail.  This depends upon the particular VM implementation.
 */
#define ___GFP_REPEAT       0x400u
...
#define __GFP_REPEAT    ((__force gfp_t)___GFP_REPEAT)    /* See above */
```

__GFP_REPEAT在分配失败后自动重试，但在尝试若干次之后会停止。

__GFP_NOFAIL
----------------------------------------

```
/* __GFP_NOFAIL: The VM implementation _must_ retry infinitely: the caller
 * cannot handle allocation failures. New users should be evaluated carefully
 * (and the flag should be used only when there is no reasonable failure policy)
 * but it is definitely preferable to use the flag rather than opencode endless
 * loop around allocator.
 */
#define ___GFP_NOFAIL       0x800u
...
#define __GFP_NOFAIL    ((__force gfp_t)___GFP_NOFAIL)    /* See above */
```

__GFP_NOFAIL在分配失败后一直重试，直至成功。

__GFP_NORETRY
----------------------------------------

```
/*  __GFP_NORETRY: The VM implementation must not retry indefinitely and will
 * return NULL when direct reclaim and memory compaction have failed to allow
 * the allocation to succeed.  The OOM killer is not called with the current
 * implementation.
 */
#define ___GFP_NORETRY      0x1000u
...
#define __GFP_NORETRY    ((__force gfp_t)___GFP_NORETRY) /* See above */
```

__GFP_MEMALLOC
----------------------------------------

```
#define ___GFP_MEMALLOC     0x2000u
...
#define __GFP_MEMALLOC    ((__force gfp_t)___GFP_MEMALLOC)/* Allow access to emergency reserves */
```

__GFP_COMP
----------------------------------------

```
#define ___GFP_COMP         0x4000u
...
#define __GFP_COMP    ((__force gfp_t)___GFP_COMP)    /* Add compound page metadata */
```

__GFP_ZERO
----------------------------------------

```
#define ___GFP_ZERO         0x8000u
...
#define __GFP_ZERO  ((__force gfp_t)___GFP_ZERO)  /* Return zeroed page on success */
```

__GFP_ZERO在分配成功时，将返回填充字节0的页。

__GFP_NOMEMALLOC
----------------------------------------

```
#define ___GFP_NOMEMALLOC   0x10000u
...
/* Don't use emergency reserves. This takes precedence over the __GFP_MEMALLOC
 * flag if both are set
 */
#define __GFP_NOMEMALLOC ((__force gfp_t)___GFP_NOMEMALLOC)
```

__GFP_HARDWALL
----------------------------------------

```
#define ___GFP_HARDWALL     0x20000u
...
#define __GFP_HARDWALL  ((__force gfp_t)___GFP_HARDWALL) /* Enforce hardwall cpuset memory allocs */
```

__GFP_HARDWALL只在NUMA系统上有意义。它限制只在分配到当前进程的各个CPU所关联的结点分配内存。
如果进程允许在所有CPU上运行（默认情况），该标志是无意义的。只有进程可以运行的CPU受限时，
该标志才有效果。

__GFP_THISNODE
----------------------------------------

```
#define ___GFP_THISNODE     0x40000u
...
#define __GFP_THISNODE    ((__force gfp_t)___GFP_THISNODE)/* No fallback, no policies */
```

__GFP_THISNODE也只在NUMA系统上有意义。如果设置该比特位，则内存分配失败的情况下不允许使用其他结点
作为备用，需要保证在当前结点或者明确指定的结点上成功分配内存。

__GFP_RECLAIMABLE
----------------------------------------

```
#define ___GFP_RECLAIMABLE  0x80000u
#define ___GFP_NOACCOUNT    0x100000u
#define ___GFP_NOTRACK      0x200000u
#define ___GFP_NO_KSWAPD    0x400000u
#define ___GFP_OTHER_NODE   0x800000u
#define ___GFP_WRITE        0x1000000u
/* If the above are modified, __GFP_BITS_SHIFT may need updating */

...

/*
 * Action modifiers - doesn't change the zoning
 *
 * __GFP_MOVABLE: Flag that this page will be movable by the page migration
 * mechanism or reclaimed
 */

#define __GFP_RECLAIMABLE ((__force gfp_t)___GFP_RECLAIMABLE) /* Page is reclaimable */
#define __GFP_NOACCOUNT   ((__force gfp_t)___GFP_NOACCOUNT) /* Don't account to kmemcg */
#define __GFP_NOTRACK    ((__force gfp_t)___GFP_NOTRACK)  /* Don't track with kmemcheck */

#define __GFP_NO_KSWAPD  ((__force gfp_t)___GFP_NO_KSWAPD)
#define __GFP_OTHER_NODE ((__force gfp_t)___GFP_OTHER_NODE) /* On behalf of other node */
#define __GFP_WRITE      ((__force gfp_t)___GFP_WRITE)    /* Allocator intends to dirty page */
```

__GFP_RECLAIMABLE和__GFP_MOVABLE是页迁移机制所需的标志。顾名思义，它们分别将分配的内存标记为
可回收的或可移动的。这影响从空闲列表的哪个子表获取内存。

由于这些标志几乎总是组合使用，内核作了一些分组，包含了用于各种标准情形的适当的标志。如果有可能
的话，在内存管理子系统之外，总是把下列分组之一用于内存分配。在内核源代码中，双下划线通常用于
内部数据和定义。而这些预定义的分组名没有双下划线前缀，这一点从侧面验证了上述说法。

path: include/linux/gfp.h
```
/* This equals 0, but use constants in case they ever change */
#define GFP_NOWAIT	(GFP_ATOMIC & ~__GFP_HIGH)
/* GFP_ATOMIC means both !wait (__GFP_WAIT not set) and use emergency pool */
#define GFP_ATOMIC	(__GFP_HIGH)
#define GFP_NOIO	(__GFP_WAIT)
#define GFP_NOFS	(__GFP_WAIT | __GFP_IO)
#define GFP_KERNEL	(__GFP_WAIT | __GFP_IO | __GFP_FS)
#define GFP_TEMPORARY	(__GFP_WAIT | __GFP_IO | __GFP_FS | \
			 __GFP_RECLAIMABLE)
#define GFP_USER	(__GFP_WAIT | __GFP_IO | __GFP_FS | __GFP_HARDWALL)
#define GFP_HIGHUSER	(GFP_USER | __GFP_HIGHMEM)
#define GFP_HIGHUSER_MOVABLE	(GFP_HIGHUSER | __GFP_MOVABLE)
#define GFP_IOFS	(__GFP_IO | __GFP_FS)
#define GFP_TRANSHUGE	(GFP_HIGHUSER_MOVABLE | __GFP_COMP | \
			 __GFP_NOMEMALLOC | __GFP_NORETRY | __GFP_NOWARN | \
			 __GFP_NO_KSWAPD)

/* This mask makes up all the page movable related flags */
#define GFP_MOVABLE_MASK (__GFP_RECLAIMABLE|__GFP_MOVABLE)

/* Control page allocator reclaim behavior */
#define GFP_RECLAIM_MASK (__GFP_WAIT|__GFP_HIGH|__GFP_IO|__GFP_FS|\
			__GFP_NOWARN|__GFP_REPEAT|__GFP_NOFAIL|\
			__GFP_NORETRY|__GFP_MEMALLOC|__GFP_NOMEMALLOC)

/* Control slab gfp mask during early boot */
#define GFP_BOOT_MASK (__GFP_BITS_MASK & ~(__GFP_WAIT|__GFP_IO|__GFP_FS))

/* Control allocation constraints */
#define GFP_CONSTRAINT_MASK (__GFP_HARDWALL|__GFP_THISNODE)

/* Do not use these with a slab allocator */
#define GFP_SLAB_BUG_MASK (__GFP_DMA32|__GFP_HIGHMEM|~__GFP_BITS_MASK)

/* Flag - indicates that the buffer will be suitable for DMA.  Ignored on some
   platforms, used as appropriate on others */

#define GFP_DMA		__GFP_DMA

/* 4GB DMA on some platforms */
#define GFP_DMA32	__GFP_DMA32
```