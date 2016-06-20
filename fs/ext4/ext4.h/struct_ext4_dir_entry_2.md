struct ext4_dir_entry_2
========================================

在经典的UNIX文件系统中，目录不过是一种特殊的文件，其中是inode指针和对应的文件名列表，
表示了当前目录下的文件和子目录。对于Ext2文件系统，也是这样。每个目录表示为一个inode，
会对其分配数据块。数据块中包含了用于描述目录项的结构。在内核源代码中，目录项结构定义如下：

path: fs/ext4/ext4.h
```
/*
 * The new version of the directory entry.  Since EXT4 structures are
 * stored in intel byte order, and the name_len field could never be
 * bigger than 255 chars, it's safe to reclaim the extra byte for the
 * file_type field.
 */
struct ext4_dir_entry_2 {
    __le32    inode;            /* Inode number */
    __le16    rec_len;        /* Directory entry length */
    __u8      name_len;        /* Name length */
    __u8      file_type;
    char      name[EXT4_NAME_LEN];    /* File name */
};
```
