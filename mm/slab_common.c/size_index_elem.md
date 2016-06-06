size_index_elem
========================================

path: mm/slab_common.c
```
static inline int size_index_elem(size_t bytes)
{
    return (bytes - 1) / 8;
}
```