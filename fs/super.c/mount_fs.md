mount_fs
========================================

Arguments
----------------------------------------

path: fs/super.c
```
struct dentry *
mount_fs(struct file_system_type *type, int flags, const char *name, void *data)
{
    struct dentry *root;
    struct super_block *sb;
    char *secdata = NULL;
    int error = -ENOMEM;

    if (data && !(type->fs_flags & FS_BINARY_MOUNTDATA)) {
        secdata = alloc_secdata();
        if (!secdata)
            goto out;

        error = security_sb_copy_data(data, secdata);
        if (error)
            goto out_free_secdata;
    }
```

type->mount
----------------------------------------

```
    root = type->mount(type, flags, name, data);
    if (IS_ERR(root)) {
        error = PTR_ERR(root);
        goto out_free_secdata;
    }
    sb = root->d_sb;
    BUG_ON(!sb);
    WARN_ON(!sb->s_bdi);
    sb->s_flags |= MS_BORN;
```

### rootfs

https://github.com/novelinux/linux-4.x.y/blob/master/init/do_mounts.c/rootfs_mount.md

security_sb_kern_mount
----------------------------------------

```
    error = security_sb_kern_mount(sb, flags, secdata);
    if (error)
        goto out_sb;
```

Return
----------------------------------------

```
    /*
     * filesystems should never set s_maxbytes larger than MAX_LFS_FILESIZE
     * but s_maxbytes was an unsigned long long for many releases. Throw
     * this warning for a little while to try and catch filesystems that
     * violate this rule.
     */
    WARN((sb->s_maxbytes < 0), "%s set sb->s_maxbytes to "
        "negative value (%lld)\n", type->name, sb->s_maxbytes);

    up_write(&sb->s_umount);
    free_secdata(secdata);
    return root;
out_sb:
    dput(root);
    deactivate_locked_super(sb);
out_free_secdata:
    free_secdata(secdata);
out:
    return ERR_PTR(error);
}
```