vunmap
========================================

path: mm/vmalloc.c
```
/**
 *    vunmap  -  release virtual mapping obtained by vmap()
 *    @addr:        memory base address
 *
 *    Free the virtually contiguous memory area starting at @addr,
 *    which was created from the page array passed to vmap().
 *
 *    Must not be called in interrupt context.
 */
void vunmap(const void *addr)
{
    BUG_ON(in_interrupt());
    might_sleep();
    if (addr)
        __vunmap(addr, 0);
}
EXPORT_SYMBOL(vunmap);
```

__vunmap
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/vmalloc.c/__vunmap.md
