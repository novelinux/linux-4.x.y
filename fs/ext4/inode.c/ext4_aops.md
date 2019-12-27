# ext4_aops

path: fs/ext4/inode.c

## ext4_readpage

```
static const struct address_space_operations ext4_aops = {
    .readpage        = ext4_readpage,
```

[ext4_readpage](./ext4_readpage.md)

## ext4_readpages

```
    .readpages        = ext4_readpages,
```

[ext4_readpages](./ext4_readpages.md)

## writepage

```
    .writepage        = ext4_writepage,
```

## writepages

```
    .writepages        = ext4_writepages,
```

https://github.com/novelinux/linux-4.x.y/tree/master/fs/ext4/inode.c/ext4_writepages.md

## write_begin

```
    .write_begin        = ext4_write_begin,
    .write_end        = ext4_write_end,
    .bmap            = ext4_bmap,
    .invalidatepage        = ext4_invalidatepage,
    .releasepage        = ext4_releasepage,
    .direct_IO        = ext4_direct_IO,
    .migratepage        = buffer_migrate_page,
    .is_partially_uptodate  = block_is_partially_uptodate,
    .error_remove_page    = generic_error_remove_page,
};
```