struct ext4_extent
========================================

path: fs/ext4/ext4_extents.h
```
/*
 * This is the extent on-disk structure.
 * It's used at the bottom of the tree.
 */
struct ext4_extent {
    __le32    ee_block;  /* first logical block extent covers */
    __le16    ee_len;    /* number of blocks covered by extent */
    __le16    ee_start_hi;  /* high 16 bits of physical block */
    __le32    ee_start_lo;  /* low 32 bits of physical block */
};
```