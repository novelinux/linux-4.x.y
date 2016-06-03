slab_get_obj
========================================

Arguments
----------------------------------------

path: mm/slab.c
```
static void *slab_get_obj(struct kmem_cache *cachep, struct page *page,
                int nodeid)
{
    void *objp;
```

index_to_obj
----------------------------------------

```
    objp = index_to_obj(cachep, page, get_free_obj(page, page->active));
    page->active++;
#if DEBUG
    WARN_ON(page_to_nid(virt_to_page(objp)) != nodeid);
#endif

    return objp;
}
```

### get_free_obj

https://github.com/novelinux/linux-4.x.y/blob/master/mm/slab.c/get_free_obj.md

### index_to_obj

https://github.com/novelinux/linux-4.x.y/blob/master/mm/slab.c/index_to_obj.md
