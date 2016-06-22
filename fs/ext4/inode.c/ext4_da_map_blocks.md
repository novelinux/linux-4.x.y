ext4_da_map_blocks
========================================

Arguments
----------------------------------------

path: fs/ext4/inode.c
```
/*
 * This function is grabs code from the very beginning of
 * ext4_map_blocks, but assumes that the caller is from delayed write
 * time. This function looks up the requested blocks and sets the
 * buffer delay bit under the protection of i_data_sem.
 */
static int ext4_da_map_blocks(struct inode *inode, sector_t iblock,
                  struct ext4_map_blocks *map,
                  struct buffer_head *bh)
{
    struct extent_status es;
    int retval;
    sector_t invalid_block = ~((sector_t) 0xffff);
#ifdef ES_AGGRESSIVE_TEST
    struct ext4_map_blocks orig_map;

    memcpy(&orig_map, map, sizeof(*map));
#endif

    if (invalid_block < ext4_blocks_count(EXT4_SB(inode->i_sb)->s_es))
        invalid_block = ~0;

    map->m_flags = 0;
    ext_debug("ext4_da_map_blocks(): inode %lu, max_blocks %u,"
          "logical block %lu\n", inode->i_ino, map->m_len,
          (unsigned long) map->m_lblk);
```

ext4_es_lookup_extent
----------------------------------------

```
    /* Lookup extent status tree firstly */
    if (ext4_es_lookup_extent(inode, iblock, &es)) {
        if (ext4_es_is_hole(&es)) {
            retval = 0;
            down_read(&EXT4_I(inode)->i_data_sem);
            goto add_delayed;
        }

        /*
         * Delayed extent could be allocated by fallocate.
         * So we need to check it.
         */
        if (ext4_es_is_delayed(&es) && !ext4_es_is_unwritten(&es)) {
            map_bh(bh, inode->i_sb, invalid_block);
            set_buffer_new(bh);
            set_buffer_delay(bh);
            return 0;
        }

        map->m_pblk = ext4_es_pblock(&es) + iblock - es.es_lblk;
        retval = es.es_len - (iblock - es.es_lblk);
        if (retval > map->m_len)
            retval = map->m_len;
        map->m_len = retval;
        if (ext4_es_is_written(&es))
            map->m_flags |= EXT4_MAP_MAPPED;
        else if (ext4_es_is_unwritten(&es))
            map->m_flags |= EXT4_MAP_UNWRITTEN;
        else
            BUG_ON(1);

#ifdef ES_AGGRESSIVE_TEST
        ext4_map_blocks_es_recheck(NULL, inode, map, &orig_map, 0);
#endif
        return retval;
    }
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/ext4/extents_status.c/ext4_es_lookup_extent.md

ext4_ext_map_blocks
----------------------------------------

```
    /*
     * Try to see if we can get the block without requesting a new
     * file system block.
     */
    down_read(&EXT4_I(inode)->i_data_sem);
    if (ext4_has_inline_data(inode))
        retval = 0;
    else if (ext4_test_inode_flag(inode, EXT4_INODE_EXTENTS))
        retval = ext4_ext_map_blocks(NULL, inode, map, 0);
    else
        retval = ext4_ind_map_blocks(NULL, inode, map, 0);
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/ext4/extents.c/ext4_ext_map_blocks.md

add_delayed
----------------------------------------

### retval == 0

#### ext4_da_reserve_space

```
add_delayed:
    if (retval == 0) {
        int ret;
        /*
         * XXX: __block_prepare_write() unmaps passed block,
         * is it OK?
         */
        /*
         * If the block was allocated from previously allocated cluster,
         * then we don't need to reserve it again. However we still need
         * to reserve metadata for every block we're going to write.
         */
        if (EXT4_SB(inode->i_sb)->s_cluster_ratio == 1 ||
            !ext4_find_delalloc_cluster(inode, map->m_lblk)) {
            ret = ext4_da_reserve_space(inode);
            if (ret) {
                /* not enough space to reserve */
                retval = ret;
                goto out_unlock;
            }
        }
```

#### ext4_es_insert_extent

```
        ret = ext4_es_insert_extent(inode, map->m_lblk, map->m_len,
                        ~0, EXTENT_STATUS_DELAYED);
        if (ret) {
            retval = ret;
            goto out_unlock;
        }

        map_bh(bh, inode->i_sb, invalid_block);
        set_buffer_new(bh);
        set_buffer_delay(bh);
```

### retval > 0

```
    } else if (retval > 0) {
        int ret;
        unsigned int status;

        if (unlikely(retval != map->m_len)) {
            ext4_warning(inode->i_sb,
                     "ES len assertion failed for inode "
                     "%lu: retval %d != map->m_len %d",
                     inode->i_ino, retval, map->m_len);
            WARN_ON(1);
        }

        status = map->m_flags & EXT4_MAP_UNWRITTEN ?
                EXTENT_STATUS_UNWRITTEN : EXTENT_STATUS_WRITTEN;
        ret = ext4_es_insert_extent(inode, map->m_lblk, map->m_len,
                        map->m_pblk, status);
        if (ret != 0)
            retval = ret;
    }

out_unlock:
    up_read((&EXT4_I(inode)->i_data_sem));

    return retval;
}
```