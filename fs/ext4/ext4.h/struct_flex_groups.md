struct flex_groups
========================================

Flexible 块组(flex_bg)是从Ext4开始引入的新特性。在一个flex_bg中，几个块组在一起组成一个
逻辑块组flex_bg。Flex_bg的第一个块组中的位图空间和inode表空间扩大为包含了flex_bg中其他块组
上位图和inode表。

比如flex_bg包含4个块组，块组0将按序包含超级块、块组描述符表、块组0-3的数据块位图、
块组0-3的inode位图、块组0-3的inode表，块组0中的其他空间用于存储文件数据。同时，
其他块组上的数据块位图、inode位图、inode表元数据就不存在了，但是super block和group descriptor
还是存在的。

path: fs/ext4/ext4.h
```
/*
 * Structure of a flex block group info
 */

struct flex_groups {
    atomic64_t  free_clusters;
    atomic_t    free_inodes;
    atomic_t    used_dirs;
};
```

Flexible块组的作用是:

* 1.聚集元数据，加速元数据载入；
* 2.使得大文件在磁盘上尽量连续；

即使开启flex_bg特性，超级块和块组描述符的冗余备份仍然位于块组的开头, Flex_bg中块组的
个数由2^ext4_super_block.s_log_groups_per_flex 给出。
