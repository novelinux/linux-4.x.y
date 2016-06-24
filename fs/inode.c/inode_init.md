inode_init
========================================

path: fs/inode.c
```
void __init inode_init(void)
{
    unsigned int loop;

    /* inode slab cache */
    inode_cachep = kmem_cache_create("inode_cache",
                     sizeof(struct inode),
                     0,
                     (SLAB_RECLAIM_ACCOUNT|SLAB_PANIC|
                     SLAB_MEM_SPREAD),
                     init_once);

    /* Hash may have been set up in inode_init_early */
    if (!hashdist)
        return;

    inode_hashtable =
        alloc_large_system_hash("Inode-cache",
                    sizeof(struct hlist_head),
                    ihash_entries,
                    14,
                    0,
                    &i_hash_shift,
                    &i_hash_mask,
                    0,
                    0);

    for (loop = 0; loop < (1U << i_hash_shift); loop++)
        INIT_HLIST_HEAD(&inode_hashtable[loop]);
}
```