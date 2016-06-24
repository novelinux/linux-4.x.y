files_init
========================================

path: fs/file_table.c
```
void __init files_init(void)
{
    filp_cachep = kmem_cache_create("filp", sizeof(struct file), 0,
            SLAB_HWCACHE_ALIGN | SLAB_PANIC, NULL);
    percpu_counter_init(&nr_files, 0, GFP_KERNEL);
}
```