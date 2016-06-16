struct super_operations
========================================

alloc_inode
----------------------------------------

path: include/linux/fs.h
```
struct super_operations {
    struct inode *(*alloc_inode)(struct super_block *sb);
```

destroy_inode
----------------------------------------

```
    void (*destroy_inode)(struct inode *);
```

destroy_inode将inode从内存和底层存储介质删除。

dirty_inode
----------------------------------------

```
    void (*dirty_inode) (struct inode *, int flags);
```

dirty_inode将传递的inode结构标记为“脏的”，因为其数据已经修改。

write_inode
----------------------------------------

```
    int (*write_inode) (struct inode *, struct writeback_control *wbc);
    int (*drop_inode) (struct inode *);
    void (*evict_inode) (struct inode *);
```

put_super
----------------------------------------

```
    void (*put_super) (struct super_block *);
```

put_super将超级块的私有信息从内存移除，这发生在文件系统卸载、该数据不再需要时。

sync_fs
----------------------------------------

```
    int (*sync_fs)(struct super_block *sb, int wait);
```

sync_fs将文件系统数据与底层块设备上的数据同步。

freeze_super
----------------------------------------

```
    int (*freeze_super) (struct super_block *);
    int (*freeze_fs) (struct super_block *);
    int (*thaw_super) (struct super_block *);
    int (*unfreeze_fs) (struct super_block *);
```

statfs
----------------------------------------

```
    int (*statfs) (struct dentry *, struct kstatfs *);
```

statfs给出有关文件系统的统计信息，例如使用和未使用的数据块的数目，或文件名的最大长度。
它与同名的系统调用有密切的协作。

```
    int (*remount_fs) (struct super_block *, int *, char *);
```

umount_begin
----------------------------------------

```
    void (*umount_begin) (struct super_block *);
```

umount_begin仅用于网络文件系统（NFS、CIFS和9fs）和用户空间文件系统（FUSE）。它允许在卸载操作
开始之前，与远程的文件系统提供者通信。仅在文件系统强制卸载时调用该方法。换句话说，它仅用于
MNT_FORCE强制内核执行umount操作时，此时可能仍然有对该文件系统的引用。

show_options
----------------------------------------

```
    int (*show_options)(struct seq_file *, struct dentry *);
```

show_options用于proc文件系统，用以显示文件系统装载的选项。show_stats提供了文件系统的统计信息，
同样用于proc文件系统。

show_devname
----------------------------------------

```
    int (*show_devname)(struct seq_file *, struct dentry *);
    int (*show_path)(struct seq_file *, struct dentry *);
```

show_stats
----------------------------------------

```
    int (*show_stats)(struct seq_file *, struct dentry *);
```

show_stats提供了文件系统的统计信息，同样用于proc文件系统。

CONFIG_QUOTA
----------------------------------------

```
#ifdef CONFIG_QUOTA
    ssize_t (*quota_read)(struct super_block *, int, char *, size_t, loff_t);
    ssize_t (*quota_write)(struct super_block *, int, const char *, size_t, loff_t);
    struct dquot **(*get_dquots)(struct inode *);
#endif
    int (*bdev_try_to_free_page)(struct super_block*, struct page*, gfp_t);
    long (*nr_cached_objects)(struct super_block *,
                  struct shrink_control *);
    long (*free_cached_objects)(struct super_block *,
                    struct shrink_control *);
};
```