dcache_init_early
========================================

path: fs/dcache.c
```
static struct hlist_bl_head *dentry_hashtable __read_mostly;
...
static void __init dcache_init_early(void)
{
    unsigned int loop;

    /* If hashes are distributed across NUMA nodes, defer
     * hash allocation until vmalloc space is available.
     */
    if (hashdist)
        return;

    dentry_hashtable =
        alloc_large_system_hash("Dentry cache",
                    sizeof(struct hlist_bl_head),
                    dhash_entries,
                    13,
                    HASH_EARLY,
                    &d_hash_shift,
                    &d_hash_mask,
                    0,
                    0);

    for (loop = 0; loop < (1U << d_hash_shift); loop++)
        INIT_HLIST_BL_HEAD(dentry_hashtable + loop);
}
```