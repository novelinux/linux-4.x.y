ext4_da_aops
========================================

path: fs/ext4/inode.c
```
static const struct address_space_operations ext4_da_aops = {
    .readpage        = ext4_readpage,
```

[ext4_readpage](./ext4_readpage)

```
    .readpages        = ext4_readpages,
    .writepage        = ext4_writepage,
    .writepages        = ext4_writepages,
```

write_begin
----------------------------------------

```
    .write_begin        = ext4_da_write_begin,
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/ext4/inode.c/ext4_da_write_begin.md

write_end
----------------------------------------

```
    .write_end        = ext4_da_write_end,
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/ext4/inode.c/ext4_da_write_end.md

bmap
----------------------------------------

```
    .bmap            = ext4_bmap,
    .invalidatepage        = ext4_da_invalidatepage,
    .releasepage        = ext4_releasepage,
    .direct_IO        = ext4_direct_IO,
    .migratepage        = buffer_migrate_page,
    .is_partially_uptodate  = block_is_partially_uptodate,
    .error_remove_page    = generic_error_remove_page,
};
```