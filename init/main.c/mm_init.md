mm_init
========================================

Code Flow
----------------------------------------

```
mm_init
  |
  +-> page_ext_init_flatmem
  |
  +-> mem_init
  |
  +-> kmem_cache_init
  |
  +-> percpu_init_late
  |
  +-> pgtable_init
  |
  +-> vmalloc_init
  |
  +-> ioremap_huge_init
```

path: init/main.c
```
/*
 * Set up kernel memory allocators
 */
static void __init mm_init(void)
{
```

page_ext_init_flatmem
----------------------------------------

```
    /*
     * page_ext requires contiguous pages,
     * bigger than MAX_ORDER unless SPARSEMEM.
     */
     page_ext_init_flatmem();
```

mem_init
--------------------------------------

在mem_init函数中Linux系统完成了Memblock切换到Buddy进行对应的物理内存管理工作.

```
     mem_init();
```

### ARM

https://github.com/novelinux/linux-4.x.y/blob/master/arch/arm/mm/init.c/mem_init.md

kmem_cache_init
----------------------------------------

```
     kmem_cache_init();
```

percpu_init_late
----------------------------------------

```
     percpu_init_late();
```

pgtable_init
----------------------------------------

```
     pgtable_init();
```

vmalloc_init
----------------------------------------

```
     vmalloc_init();
```

ioremap_huge_init
----------------------------------------

```
     ioremap_huge_init();
}
```
