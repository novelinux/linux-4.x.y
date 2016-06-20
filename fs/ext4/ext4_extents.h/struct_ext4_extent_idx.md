struct ext4_extent_idx
========================================

path: fs/ext4/ext4_extents.h
```
/*
 * This is index on-disk structure.
 * It's used at all the levels except the bottom.
 */
struct ext4_extent_idx {
    __le32    ei_block;    /* index covers logical blocks from 'block' */
    __le32    ei_leaf_lo;    /* pointer to the physical block of the next *
                 * level. leaf or next index could be there */
    __le16    ei_leaf_hi;    /* high 16 bits of physical block */
    __u16    ei_unused;
};
```