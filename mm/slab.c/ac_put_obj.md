ac_put_obj
========================================

Arguments
----------------------------------------

path: mm/slab.c
```
static inline void ac_put_obj(struct kmem_cache *cachep, struct array_cache *ac,
                                void *objp)
{
```

__ac_put_obj
----------------------------------------

```
    if (unlikely(sk_memalloc_socks()))
        objp = __ac_put_obj(cachep, ac, objp);
```

https://github.com/novelinux/linux-4.x.y/blob/master/mm/slab.c/__ac_put_obj.md

ac->entry
----------------------------------------

将对应的object添加到ac->entry中去.

```
    ac->entry[ac->avail++] = objp;
}
```