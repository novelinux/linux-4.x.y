ext4_journalled_aops
========================================

path: fs/ext4/inode.c
```
static const struct address_space_operations ext4_journalled_aops = {
    .readpage        = ext4_readpage,
    .readpages        = ext4_readpages,
    .writepage        = ext4_writepage,
    .writepages        = ext4_writepages,
    .write_begin        = ext4_write_begin,
    .write_end        = ext4_journalled_write_end,
    .set_page_dirty        = ext4_journalled_set_page_dirty,
    .bmap            = ext4_bmap,
    .invalidatepage        = ext4_journalled_invalidatepage,
    .releasepage        = ext4_releasepage,
    .direct_IO        = ext4_direct_IO,
    .is_partially_uptodate  = block_is_partially_uptodate,
    .error_remove_page    = generic_error_remove_page,
};
```