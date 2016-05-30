vfree
========================================

path: mm/vmalloc.c
```
/**
 *    vfree  -  release memory allocated by vmalloc()
 *    @addr:        memory base address
 *
 *    Free the virtually continuous memory area starting at @addr, as
 *    obtained from vmalloc(), vmalloc_32() or __vmalloc(). If @addr is
 *    NULL, no operation is performed.
 *
 *    Must not be called in NMI context (strictly speaking, only if we don't
 *    have CONFIG_ARCH_HAVE_NMI_SAFE_CMPXCHG, but making the calling
 *    conventions for vfree() arch-depenedent would be a really bad idea)
 *
 *    NOTE: assumes that the object at *addr has a size >= sizeof(llist_node)
 */
void vfree(const void *addr)
{
    BUG_ON(in_nmi());

    kmemleak_free(addr);

    if (!addr)
        return;
    if (unlikely(in_interrupt())) {
        struct vfree_deferred *p = this_cpu_ptr(&vfree_deferred);
        if (llist_add((struct llist_node *)addr, &p->list))
            schedule_work(&p->wq);
    } else
        __vunmap(addr, 1);
}
EXPORT_SYMBOL(vfree);
```

__vunmap
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/vmalloc.c/__vunmap.md
