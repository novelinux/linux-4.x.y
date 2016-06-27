init_mount_tree
========================================

Arguments
----------------------------------------

path: fs/namespace.c
```
static void __init init_mount_tree(void)
{
    struct vfsmount *mnt;
    struct mnt_namespace *ns;
    struct path root;
    struct file_system_type *type;
```

get_fs_type
----------------------------------------

```
    type = get_fs_type("rootfs");
    if (!type)
        panic("Can't find rootfs type");
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/filesystems.c/get_fs_type.md

vfs_kern_mount
----------------------------------------

```
    mnt = vfs_kern_mount(type, 0, "rootfs", NULL);
    put_filesystem(type);
    if (IS_ERR(mnt))
        panic("Can't create rootfs");
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/namespace.c/vfs_kern_mount.md

create_mnt_ns
----------------------------------------

调用create_mnt_ns()创建命名空间，并设置该命名空间的挂载点为rootfs的挂载点，同时将rootfs
的挂载点链接到该命名空间的双向链表中。

```
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

https://github.com/novelinux/linux-4.x.y/blob/master/fs/namespace.c/create_mnt_ns.md
