set_free_obj
========================================

path: mm/slab.c
```
static inline void set_free_obj(struct page *page,
                    unsigned int idx, freelist_idx_t val)
{
    ((freelist_idx_t *)(page->freelist))[idx] = val;
}
```