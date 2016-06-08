cache_init_objs
========================================

Arguments
----------------------------------------

path: mm/slab.c
```
static void cache_init_objs(struct kmem_cache *cachep,
                struct page *page)
{
    int i;
```

index_to_obj
----------------------------------------

```
    for (i = 0; i < cachep->num; i++) {
        void *objp = index_to_obj(cachep, page, i);
#if DEBUG
        ...
#else
        if (cachep->ctor)
            cachep->ctor(objp);
#endif
```

https://github.com/novelinux/linux-4.x.y/blob/master/mm/slab.c/index_to_obj.md

set_free_obj
----------------------------------------

```
        set_obj_status(page, i, OBJECT_FREE);
        set_free_obj(page, i, i);
    }
}
```

https://github.com/novelinux/linux-4.x.y/blob/master/mm/slab.c/set_free_obj.md