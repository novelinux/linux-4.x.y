struct ext4_ext_path
========================================

path: fs/ext4/ext4_extents.h
```
/*
 * Array of ext4_ext_path contains path to some extent.
 * Creation/lookup routines use it for traversal/splitting/etc.
 * Truncate uses it to simulate recursive walking.
 */
struct ext4_ext_path {
    ext4_fsblk_t               p_block;
    __u16                      p_depth;
    __u16                      p_maxdepth;
    struct ext4_extent        *p_ext;
    struct ext4_extent_idx    *p_idx;
    struct ext4_extent_header *p_hdr;
    struct buffer_head        *p_bh;
};
```