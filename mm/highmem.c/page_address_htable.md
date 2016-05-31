page_address_htable
========================================

path: mm/highmem.c
```
/*
 * Hash table bucket
 */
static struct page_address_slot {
    struct list_head lh;            /* List of page_address_maps */
    spinlock_t lock;            /* Protect this bucket's list */
} ____cacheline_aligned_in_smp page_address_htable[1<<PA_HASH_ORDER];
```