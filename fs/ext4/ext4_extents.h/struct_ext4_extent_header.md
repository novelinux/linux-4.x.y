struct ext4_extent_header
========================================

path: fs/ext4/ext4_extents.h
```
/*
 * Each block (leaves and indexes), even inode-stored has header.
 */
struct ext4_extent_header {
    __le16    eh_magic;    /* probably will support different formats */
    __le16    eh_entries;    /* number of valid entries */
    __le16    eh_max;        /* capacity of store in entries */
    __le16    eh_depth;    /* has tree real underlying blocks? */
    __le32    eh_generation;    /* generation of the tree */
};
```