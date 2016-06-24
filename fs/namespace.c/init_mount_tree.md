init_mount_tree
========================================

path: fs/namespace.c
```
static void __init init_mount_tree(void)
{
    struct vfsmount *mnt;
    struct mnt_namespace *ns;
    struct path root;
    struct file_system_type *type;

    type = get_fs_type("rootfs");
    if (!type)
        panic("Can't find rootfs type");
    mnt = vfs_kern_mount(type, 0, "rootfs", NULL);
    put_filesystem(type);
    if (IS_ERR(mnt))
        panic("Can't create rootfs");

    ns = create_mnt_ns(mnt);
    if (IS_ERR(ns))
        panic("Can't allocate initial namespace");

    init_task.nsproxy->mnt_ns = ns;
    get_mnt_ns(ns);

    root.mnt = mnt;
    root.dentry = mnt->mnt_root;
    mnt->mnt_flags |= MNT_LOCKED;

    set_fs_pwd(current->fs, &root);
    set_fs_root(current->fs, &root);
}
```