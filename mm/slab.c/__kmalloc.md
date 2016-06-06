__kmalloc
========================================

path: mm/slab.c
```
void *__kmalloc(size_t size, gfp_t flags)
{
    return __do_kmalloc(size, flags, _RET_IP_);
}
EXPORT_SYMBOL(__kmalloc);
```

__do_kmalloc
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/slab.c/__do_kmalloc.md
