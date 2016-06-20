ext4_ext_truncate
========================================

Arguments
----------------------------------------

path: fs/ext4/extents.c
```
void ext4_ext_truncate(handle_t *handle, struct inode *inode)
{
    struct super_block *sb = inode->i_sb;
    ext4_lblk_t last_block;
    int err = 0;
```

ext4_mark_inode_dirty
----------------------------------------

```
    /*
     * TODO: optimization is possible here.
     * Probably we need not scan at all,
     * because page truncation is enough.
     */

    /* we have to know where to truncate from in crash case */
    EXT4_I(inode)->i_disksize = inode->i_size;
    ext4_mark_inode_dirty(handle, inode);

    last_block = (inode->i_size + sb->s_blocksize - 1)
            >> EXT4_BLOCK_SIZE_BITS(sb);
```

retry
----------------------------------------

### ext4_es_remove_extent

```
retry:
xo    err = ext4_es_remove_extent(inode, last_block,
                    EXT_MAX_BLOCKS - last_block);
    if (err == -ENOMEM) {
        cond_resched();
        congestion_wait(BLK_RW_ASYNC, HZ/50);
        goto retry;
    }
    if (err) {
        ext4_std_error(inode->i_sb, err);
        return;
    }
```

### ext4_ext_remove_space

```
    err = ext4_ext_remove_space(inode, last_block, EXT_MAX_BLOCKS - 1);
    ext4_std_error(inode->i_sb, err);
}
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/ext4/extents.c/ext4_ext_remove_space.md
