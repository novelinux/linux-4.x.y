kfree
========================================

path: mm/slab.c
```
/**
 * kfree - free previously allocated memory
 * @objp: pointer returned by kmalloc.
 *
 * If @objp is NULL, no operation is performed.
 *
 * Don't free memory not originally allocated by kmalloc()
 * or you will run into trouble.
 */
void kfree(const void *objp)
{
    struct kmem_cache *c;
    unsigned long flags;

    trace_kfree(_RET_IP_, objp);

    if (unlikely(ZERO_OR_NULL_PTR(objp)))
        return;
    local_irq_save(flags);
    kfree_debugcheck(objp);
    c = virt_to_cache(objp);
    debug_check_no_locks_freed(objp, c->object_size);

    debug_check_no_obj_freed(objp, c->object_size);
    __cache_free(c, (void *)objp, _RET_IP_);
    local_irq_restore(flags);
}
EXPORT_SYMBOL(kfree);
```

__cache_free
----------------------------------------

https://github.com/novelinux/linux-4.x.y/blob/master/mm/slab.c/__cache_free.md
