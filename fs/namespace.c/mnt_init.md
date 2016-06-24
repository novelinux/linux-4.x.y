mnt_init
========================================

path: fs/namespace.c
```
void __init mnt_init(void)
{
    unsigned u;
    int err;

    mnt_cache = kmem_cache_create("mnt_cache", sizeof(struct mount),
            0, SLAB_HWCACHE_ALIGN | SLAB_PANIC, NULL);

    mount_hashtable = alloc_large_system_hash("Mount-cache",
                sizeof(struct hlist_head),
                mhash_entries, 19,
                0,
                &m_hash_shift, &m_hash_mask, 0, 0);
    mountpoint_hashtable = alloc_large_system_hash("Mountpoint-cache",
                sizeof(struct hlist_head),
                mphash_entries, 19,
                0,
                &mp_hash_shift, &mp_hash_mask, 0, 0);

    if (!mount_hashtable || !mountpoint_hashtable)
        panic("Failed to allocate mount hash table\n");

    for (u = 0; u <= m_hash_mask; u++)
        INIT_HLIST_HEAD(&mount_hashtable[u]);
    for (u = 0; u <= mp_hash_mask; u++)
        INIT_HLIST_HEAD(&mountpoint_hashtable[u]);

    kernfs_init();

    err = sysfs_init();
    if (err)
        printk(KERN_WARNING "%s: sysfs_init error: %d\n",
            __func__, err);
    fs_kobj = kobject_create_and_add("fs", NULL);
    if (!fs_kobj)
        printk(KERN_WARNING "%s: kobj create error\n", __func__);
```

init_rootfs
----------------------------------------

```
    init_rootfs();
```

https://github.com/novelinux/linux-4.x.y/tree/master/init/do_mounts.c/init_rootfs.md

init_mount_tree
----------------------------------------

```
    init_mount_tree();
}
```
