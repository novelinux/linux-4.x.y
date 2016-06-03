get_free_obj
========================================

path: mm/slab.c
```
static inline freelist_idx_t get_free_obj(struct page *page, unsigned int idx)
{
    return ((freelist_idx_t *)page->freelist)[idx];
}
```
