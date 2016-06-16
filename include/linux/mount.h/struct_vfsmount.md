struct vfsmount
========================================

每个装载的文件系统都对应于一个vfsmount结构的实例，其定义如下：

mnt_root
----------------------------------------

path: include/linux/mount.h
```
struct vfsmount {
    struct dentry *mnt_root;    /* root of the mounted tree */
```

文件系统本身的相对根目录所对应的dentry保存在mnt_root中。

mnt_sb
----------------------------------------

```
    struct super_block *mnt_sb;    /* pointer to superblock */
```

mnt_sb指针建立了与相关的超级块之间的关联(对每个装载的文件系统而言，都有且只有一个超级块实例)。

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/fs.h/struct_super_block.md

mnt_flags
----------------------------------------

```
    int mnt_flags;
};
```

在nmt_flags可以设置各种独立于文件系统的标志。以下常数列出了所有可能的标志：

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/mount.h/struct_vfsmount.mnt_flags.md
