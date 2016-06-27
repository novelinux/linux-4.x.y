vfs_kern_mount
========================================

Arguments
----------------------------------------

path: fs/namespace.c
```
struct vfsmount *
vfs_kern_mount(struct file_system_type *type, int flags, const char *name, void *data)
{
    struct mount *mnt;
    struct dentry *root;

    if (!type)
        return ERR_PTR(-ENODEV);
```

alloc_vfsmnt
----------------------------------------

```
    mnt = alloc_vfsmnt(name);
    if (!mnt)
        return ERR_PTR(-ENOMEM);

    if (flags & MS_KERNMOUNT)
        mnt->mnt.mnt_flags = MNT_INTERNAL;
```

mount_fs
----------------------------------------

```
    root = mount_fs(type, flags, name, data);
    if (IS_ERR(root)) {
        mnt_free_id(mnt);
        free_vfsmnt(mnt);
        return ERR_CAST(root);
    }
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/super.c/mount_fs.md

Intialization and Return
----------------------------------------

```
    mnt->mnt.mnt_root = root;
    mnt->mnt.mnt_sb = root->d_sb;
    mnt->mnt_mountpoint = mnt->mnt.mnt_root;
    mnt->mnt_parent = mnt;
    lock_mount_hash();
    list_add_tail(&mnt->mnt_instance, &root->d_sb->s_mounts);
    unlock_mount_hash();
    return &mnt->mnt;
}
EXPORT_SYMBOL_GPL(vfs_kern_mount);
```
