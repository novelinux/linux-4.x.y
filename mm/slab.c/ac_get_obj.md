ac_get_obj
========================================

Arguments
----------------------------------------

path: mm/slab.c
```
static inline void *ac_get_obj(struct kmem_cache *cachep,
            struct array_cache *ac, gfp_t flags, bool force_refill)
{
    void *objp;
```

__ac_get_obj
----------------------------------------

```
    if (unlikely(sk_memalloc_socks()))
        objp = __ac_get_obj(cachep, ac, flags, force_refill);
    else
        objp = ac->entry[--ac->avail];

    return objp;
}
```

https://github.com/novelinux/linux-4.x.y/blob/master/mm/slab.c/__ac_get_obj.md
