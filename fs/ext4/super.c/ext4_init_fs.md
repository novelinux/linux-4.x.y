ext4_init_fs
========================================

Arguments
----------------------------------------

path: fs/ext4/super.c
```
static int __init ext4_init_fs(void)
{
    int i, err;

    ratelimit_state_init(&ext4_mount_msg_ratelimit, 30 * HZ, 64);
    ext4_li_info = NULL;
    mutex_init(&ext4_li_mtx);

    /* Build-time check for flags consistency */
    ext4_check_flag_values();

    for (i = 0; i < EXT4_WQ_HASH_SZ; i++) {
        mutex_init(&ext4__aio_mutex[i]);
        init_waitqueue_head(&ext4__ioend_wq[i]);
    }

    err = ext4_init_es();
    if (err)
        return err;

    err = ext4_init_pageio();
    if (err)
        goto out7;

    err = ext4_init_system_zone();
    if (err)
        goto out6;
    ext4_kset = kset_create_and_add("ext4", NULL, fs_kobj);
    if (!ext4_kset) {
        err = -ENOMEM;
        goto out5;
    }
    ext4_proc_root = proc_mkdir("fs/ext4", NULL);

    err = ext4_init_feat_adverts();
    if (err)
        goto out4;

    err = ext4_init_mballoc();
    if (err)
        goto out2;
    else
        ext4_mballoc_ready = 1;
    err = init_inodecache();
    if (err)
        goto out1;
    register_as_ext3();
    register_as_ext2();
```

register fs
----------------------------------------

```
    err = register_filesystem(&ext4_fs_type);
    if (err)
        goto out;

    return 0;
```

### register_filesystem

https://github.com/novelinux/linux-4.x.y/tree/master/fs/filesystems.c/register_filesystem.md

### ext4_fs_type

https://github.com/novelinux/linux-4.x.y/tree/master/fs/ext4/super.c/ext4_fs_type.md

out
----------------------------------------

```
out:
    unregister_as_ext2();
    unregister_as_ext3();
    destroy_inodecache();
out1:
    ext4_mballoc_ready = 0;
    ext4_exit_mballoc();
out2:
    ext4_exit_feat_adverts();
out4:
    if (ext4_proc_root)
        remove_proc_entry("fs/ext4", NULL);
    kset_unregister(ext4_kset);
out5:
    ext4_exit_system_zone();
out6:
    ext4_exit_pageio();
out7:
    ext4_exit_es();

    return err;
}
...
module_init(ext4_init_fs)
```