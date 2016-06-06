slab_put_obj
========================================

Arguments
----------------------------------------

path: mm/slab.c
```
static void slab_put_obj(struct kmem_cache *cachep, struct page *page,
                void *objp, int nodeid)
{
```

obj_to_index
----------------------------------------

```
    unsigned int objnr = obj_to_index(cachep, page, objp);
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/slab.c/obj_to_index.md

set_free_obj
----------------------------------------

```
    page->active--;
    set_free_obj(page, page->active, objnr);
}
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/slab.c/set_free_obj.md
