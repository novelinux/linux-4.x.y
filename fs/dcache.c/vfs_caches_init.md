vfs_caches_init
========================================

dcache_init
----------------------------------------

path: fs/dcache.c
```
void __init vfs_caches_init(void)
{
    names_cachep = kmem_cache_create("names_cache", PATH_MAX, 0,
            SLAB_HWCACHE_ALIGN|SLAB_PANIC, NULL);

    dcache_init();
```

https://github.com/novelinux/linux-4.x.y/tree/master/fs/dcache.c/dcache_init.md

inode_init
----------------------------------------

```
    inode_init();
```

https://github.com/novelinux/linux-4.x.y/tree/master/fs/inode.c/inode_init.md

files_init
----------------------------------------

```
    files_init();
```

https://github.com/novelinux/linux-4.x.y/tree/master/fs/file_table.c/files_init.md

files_maxfiles_init
----------------------------------------

```
    files_maxfiles_init();
```

https://github.com/novelinux/linux-4.x.y/tree/master/fs/file_table.c/files_maxfiles_init.md

mnt_init
----------------------------------------

```
    mnt_init();
```

https://github.com/novelinux/linux-4.x.y/tree/master/fs/namespace.c/mnt_init.md

bdev_cache_init
----------------------------------------

```
    bdev_cache_init();
```

chrdev_init
----------------------------------------

```
    chrdev_init();
}
```