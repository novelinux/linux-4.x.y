ext4_da_get_block_prep
========================================

Arguments
----------------------------------------

path: fs/ext4/inode.c
```
/*
 * This is a special get_block_t callback which is used by
 * ext4_da_write_begin().  It will either return mapped block or
 * reserve space for a single block.
 *
 * For delayed buffer_head we have BH_Mapped, BH_New, BH_Delay set.
 * We also have b_blocknr = -1 and b_bdev initialized properly
 *
 * For unwritten buffer_head we have BH_Mapped, BH_New, BH_Unwritten set.
 * We also have b_blocknr = physicalblock mapping unwritten extent and b_bdev
 * initialized properly.
 */
int ext4_da_get_block_prep(struct inode *inode, sector_t iblock,
               struct buffer_head *bh, int create)
{
    struct ext4_map_blocks map;
    int ret = 0;

    BUG_ON(create == 0);
    BUG_ON(bh->b_size != inode->i_sb->s_blocksize);

    map.m_lblk = iblock;
    map.m_len = 1;
```

ext4_da_map_blocks
----------------------------------------

```
    /*
     * first, we need to know whether the block is allocated already
     * preallocated blocks are unmapped but should treated
     * the same as allocated blocks.
     */
    ret = ext4_da_map_blocks(inode, iblock, &map, bh);
    if (ret <= 0)
        return ret;
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/ext4/inode.c/ext4_da_map_blocks.md

map_bh
----------------------------------------

```
    map_bh(bh, inode->i_sb, map.m_pblk);
    bh->b_state = (bh->b_state & ~EXT4_MAP_FLAGS) | map.m_flags;

    if (buffer_unwritten(bh)) {
        /* A delayed write to unwritten bh should be marked
         * new and mapped.  Mapped ensures that we don't do
         * get_block multiple times when we write to the same
         * offset and new ensures that we do proper zero out
         * for partial write.
         */
        set_buffer_new(bh);
        set_buffer_mapped(bh);
    }
    return 0;
}
```