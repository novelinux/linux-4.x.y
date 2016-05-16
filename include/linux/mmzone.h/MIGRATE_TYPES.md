MIGRATE_TYPES
========================================

MIGRATE_UNMOVABLE
----------------------------------------

path: include/linux/mmzone.h
```
enum {
     MIGRATE_UNMOVABLE,
```

不可移动页: 在内存中有固定位置，不能移动到其他地方。核心内核分配的大多数内存属于该类别。

MIGRATE_RECLAIMABLE
----------------------------------------

```
     MIGRATE_RECLAIMABLE,
```

不可移动页: 在内存中有固定位置，不能移动到其他地方。核心内核分配的大多数内存属于该类别。

MIGRATE_MOVABLE
----------------------------------------

```
     MIGRATE_MOVABLE,
```

可移动页: 可以随意地移动。属于用户空间应用程序的页属于该类别。它们是通过页表映射的。
如果它们复制到新位置，页表项可以相应地更新，应用程序不会注意到任何事。

MIGRATE_RESERVE
----------------------------------------

```
     MIGRATE_PCPTYPES,  /* the number of types on the pcp lists */
     MIGRATE_RESERVE = MIGRATE_PCPTYPES,
```

如果向具有特定可移动性的列表请求分配内存失败，这种紧急情况下可从MIGRATE_RESERVE分配内存,对应的
列表在内存子系统初始化期间用setup_zone_migrate_reserve填充.

MIGRATE_CMA
----------------------------------------

```
#ifdef CONFIG_CMA
     /*
      * MIGRATE_CMA migration type is designed to mimic the way
      * ZONE_MOVABLE works.  Only movable pages can be allocated
      * from MIGRATE_CMA pageblocks and page allocator never
      * implicitly change migration type of MIGRATE_CMA pageblock.
      *
      * The way to use it is to change migratetype of a range of
      * pageblocks to MIGRATE_CMA which can be done by
      * __free_pageblock_cma() function.  What is important though
      * is that a range of pageblocks must be aligned to
      * MAX_ORDER_NR_PAGES should biggest page be bigger then
      * a single pageblock.
      */
      MIGRATE_CMA,
#endif
```

MIGRATE_ISOLATE
----------------------------------------

```
#ifdef CONFIG_MEMORY_ISOLATION
      MIGRATE_ISOLATE, /* can't allocate from here */
#endif
```

MIGRATE_ISOLATE是一个特殊的虚拟区域，用于跨越NUMA结点移动物理内存页。在大型系统上，它有益于
将物理内存页移动到接近于使用该页最频繁的CPU。

MIGRATE_TYPES
----------------------------------------

```
      MIGRATE_TYPES
};
```

MIGRATE_TYPES只是表示迁移类型的数目，也不代表具体的区域。