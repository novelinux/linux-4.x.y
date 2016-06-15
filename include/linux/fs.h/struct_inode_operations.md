struct inode_operations
========================================

内核提供了大量函数，对inode进行操作。为此定义了一个函数指针的集合，以抽象这些操作，
因为实际数据是通过具体文件系统的实现操作的。调用接口总是保持不变，但实际工作是由
特定于实现的函数完成的。

lookup
----------------------------------------

path: include/linux/fs.h
```
struct inode_operations {
    struct dentry * (*lookup) (struct inode *,struct dentry *, unsigned int);
```

lookup根据文件系统对象的名称（表示为字符串）查找其inode实例。

follow_link
----------------------------------------

```
    const char * (*follow_link) (struct dentry *, void **);
```

follow_link根据符号链接查找目标文件的inode。因为符号链接可能是跨文件系统边界的，该例程的
实现通常非常短，实际工作很快委托给一般的VFS例程完成。

permission
----------------------------------------

```
    int (*permission) (struct inode *, int);
    struct posix_acl * (*get_acl)(struct inode *, int);

    int (*readlink) (struct dentry *, char __user *,int);
    void (*put_link) (struct inode *, void *);

    int (*create) (struct inode *,struct dentry *, umode_t, bool);
```

link
----------------------------------------

```
    int (*link) (struct dentry *,struct inode *,struct dentry *);
```

unlink
----------------------------------------

```
    int (*unlink) (struct inode *,struct dentry *);
```

unlink用于删除文件。但根据上文的描述，如果硬链接的引用计数器表明该inode仍然被多个文件使用，
则不会执行删除操作。

symlink
----------------------------------------

```
    int (*symlink) (struct inode *,struct dentry *,const char *);
    int (*mkdir) (struct inode *,struct dentry *,umode_t);
    int (*rmdir) (struct inode *,struct dentry *);
    int (*mknod) (struct inode *,struct dentry *,umode_t,dev_t);
    int (*rename) (struct inode *, struct dentry *,
            struct inode *, struct dentry *);
    int (*rename2) (struct inode *, struct dentry *,
            struct inode *, struct dentry *, unsigned int);
    int (*setattr) (struct dentry *, struct iattr *);
    int (*getattr) (struct vfsmount *mnt, struct dentry *, struct kstat *);
    int (*setxattr) (struct dentry *, const char *,const void *,size_t,int);
    ssize_t (*getxattr) (struct dentry *, const char *, void *, size_t);
    ssize_t (*listxattr) (struct dentry *, char *, size_t);
    int (*removexattr) (struct dentry *, const char *);
    int (*fiemap)(struct inode *, struct fiemap_extent_info *, u64 start,
              u64 len);
    int (*update_time)(struct inode *, struct timespec *, int);
    int (*atomic_open)(struct inode *, struct dentry *,
               struct file *, unsigned open_flag,
               umode_t create_mode, int *opened);
    int (*tmpfile) (struct inode *, struct dentry *, umode_t);
    int (*set_acl)(struct inode *, struct posix_acl *, int);

    /* WARNING: probably going away soon, do not use! */
} ____cacheline_aligned;
```
