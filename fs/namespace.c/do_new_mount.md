do_new_mount
========================================

Arguments
----------------------------------------

path: fs/namespace.c
```
/*
 * create a new mount for userspace and request it to be added into the
 * namespace's tree
 */
static int do_new_mount(struct path *path, const char *fstype, int flags,
            int mnt_flags, const char *name, void *data)
{
    struct file_system_type *type;
    struct user_namespace *user_ns = current->nsproxy->mnt_ns->user_ns;
    struct vfsmount *mnt;
    int err;

    if (!fstype)
        return -EINVAL;

    type = get_fs_type(fstype);
    if (!type)
        return -ENODEV;

    if (user_ns != &init_user_ns) {
        if (!(type->fs_flags & FS_USERNS_MOUNT)) {
            put_filesystem(type);
            return -EPERM;
        }
        /* Only in special cases allow devices from mounts
         * created outside the initial user namespace.
         */
        if (!(type->fs_flags & FS_USERNS_DEV_MOUNT)) {
            flags |= MS_NODEV;
            mnt_flags |= MNT_NODEV | MNT_LOCK_NODEV;
        }
        if (type->fs_flags & FS_USERNS_VISIBLE) {
            if (!fs_fully_visible(type, &mnt_flags))
                return -EPERM;
        }
    }
```

vfs_kern_mount
----------------------------------------

```
    mnt = vfs_kern_mount(type, flags, name, data);
    if (!IS_ERR(mnt) && (type->fs_flags & FS_HAS_SUBTYPE) &&
        !mnt->mnt_sb->s_subtype)
        mnt = fs_set_subtype(mnt, fstype);
    put_filesystem(type);
    if (IS_ERR(mnt))
        return PTR_ERR(mnt);
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/namespace.c/vfs_kern_mount.md

do_add_mount
----------------------------------------

```
    err = do_add_mount(real_mount(mnt), path, mnt_flags);
    if (err)
        mntput(mnt);
    return err;
}
```