struct path
========================================

mnt
----------------------------------------

path: include/linux/path.h
```
struct path {
    struct vfsmount *mnt;
```

有关所在文件系统的信息包含在structvfs_mount中.

dentry
----------------------------------------

```
    struct dentry *dentry;
};
```

struct dentry提供了文件名和inode之间的关联.