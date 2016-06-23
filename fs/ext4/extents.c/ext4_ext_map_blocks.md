ext4_ext_map_blocks
========================================

Comments
----------------------------------------

path: fs/ext4/extents.c
```
/*
 * Block allocation/map/preallocation routine for extents based files
 *
 *
 * Need to be called with
 * down_read(&EXT4_I(inode)->i_data_sem) if not allocating file system block
 * (ie, create is zero). Otherwise down_write(&EXT4_I(inode)->i_data_sem)
 *
 * return > 0, number of of blocks already mapped/allocated
 *          if create == 0 and these are pre-allocated blocks
 *              buffer head is unmapped
 *          otherwise blocks are mapped
 *
 * return = 0, if plain look up failed (blocks have not been allocated)
 *          buffer head is unmapped
 *
 * return < 0, error case.
 */
```

Arguments
----------------------------------------

```
int ext4_ext_map_blocks(handle_t *handle, struct inode *inode,
            struct ext4_map_blocks *map, int flags)
{
    struct ext4_ext_path *path = NULL;
    struct ext4_extent newex, *ex, *ex2;
    struct ext4_sb_info *sbi = EXT4_SB(inode->i_sb);
    ext4_fsblk_t newblock = 0;
    int free_on_err = 0, err = 0, depth, ret;
    unsigned int allocated = 0, offset = 0;
    unsigned int allocated_clusters = 0;
    struct ext4_allocation_request ar;
    ext4_io_end_t *io = ext4_inode_aio(inode);
    ext4_lblk_t cluster_offset;
    int set_unwritten = 0;
    bool map_from_cluster = false;

    ext_debug("blocks %u/%u requested for inode %lu\n",
          map->m_lblk, map->m_len, inode->i_ino);
    trace_ext4_ext_map_blocks_enter(inode, map->m_lblk, map->m_len, flags);
```

ext4_find_extent
----------------------------------------

```
    /* find extent for this block */
    path = ext4_find_extent(inode, map->m_lblk, NULL, 0);
    if (IS_ERR(path)) {
        err = PTR_ERR(path);
        path = NULL;
        goto out2;
    }

    depth = ext_depth(inode);

    /*
     * consistent leaf must not be empty;
     * this situation is possible, though, _during_ tree modification;
     * this is why assert can't be put in ext4_find_extent()
     */
    if (unlikely(path[depth].p_ext == NULL && depth != 0)) {
        EXT4_ERROR_INODE(inode, "bad extent address "
                 "lblock: %lu, depth: %d pblock %lld",
                 (unsigned long) map->m_lblk, depth,
                 path[depth].p_block);
        err = -EIO;
        goto out2;
    }

    ex = path[depth].p_ext;
    if (ex) {
        ext4_lblk_t ee_block = le32_to_cpu(ex->ee_block);
        ext4_fsblk_t ee_start = ext4_ext_pblock(ex);
        unsigned short ee_len;


        /*
         * unwritten extents are treated as holes, except that
         * we split out initialized portions during a write.
         */
        ee_len = ext4_ext_get_actual_len(ex);

        trace_ext4_ext_show_extent(inode, ee_block, ee_start, ee_len);

        /* if found extent covers block, simply return it */
        if (in_range(map->m_lblk, ee_block, ee_len)) {
            newblock = map->m_lblk - ee_block + ee_start;
            /* number of remaining blocks in the extent */
            allocated = ee_len - (map->m_lblk - ee_block);
            ext_debug("%u fit into %u:%d -> %llu\n", map->m_lblk,
                  ee_block, ee_len, newblock);

            /*
             * If the extent is initialized check whether the
             * caller wants to convert it to unwritten.
             */
            if ((!ext4_ext_is_unwritten(ex)) &&
                (flags & EXT4_GET_BLOCKS_CONVERT_UNWRITTEN)) {
                allocated = convert_initialized_extent(
                        handle, inode, map, &path,
                        flags, allocated, newblock);
                goto out2;
            } else if (!ext4_ext_is_unwritten(ex))
                goto out;

            ret = ext4_ext_handle_unwritten_extents(
                handle, inode, map, &path, flags,
                allocated, newblock);
            if (ret < 0)
                err = ret;
            else
                allocated = ret;
            goto out2;
        }
    }

    /*
     * requested block isn't allocated yet;
     * we couldn't try to create block if create flag is zero
     */
    if ((flags & EXT4_GET_BLOCKS_CREATE) == 0) {
        /*
         * put just found gap into cache to speed up
         * subsequent requests
         */
        ext4_ext_put_gap_in_cache(inode, path, map->m_lblk);
        goto out2;
    }

    /*
     * Okay, we need to do block allocation.
     */
    newex.ee_block = cpu_to_le32(map->m_lblk);
    cluster_offset = EXT4_LBLK_COFF(sbi, map->m_lblk);

    /*
     * If we are doing bigalloc, check to see if the extent returned
     * by ext4_find_extent() implies a cluster we can use.
     */
    if (cluster_offset && ex &&
        get_implied_cluster_alloc(inode->i_sb, map, ex, path)) {
        ar.len = allocated = map->m_len;
        newblock = map->m_pblk;
        map_from_cluster = true;
        goto got_allocated_blocks;
    }

    /* find neighbour allocated blocks */
    ar.lleft = map->m_lblk;
    err = ext4_ext_search_left(inode, path, &ar.lleft, &ar.pleft);
    if (err)
        goto out2;
    ar.lright = map->m_lblk;
    ex2 = NULL;
    err = ext4_ext_search_right(inode, path, &ar.lright, &ar.pright, &ex2);
    if (err)
        goto out2;

    /* Check if the extent after searching to the right implies a
     * cluster we can use. */
    if ((sbi->s_cluster_ratio > 1) && ex2 &&
        get_implied_cluster_alloc(inode->i_sb, map, ex2, path)) {
        ar.len = allocated = map->m_len;
        newblock = map->m_pblk;
        map_from_cluster = true;
        goto got_allocated_blocks;
    }

    /*
     * See if request is beyond maximum number of blocks we can have in
     * a single extent. For an initialized extent this limit is
     * EXT_INIT_MAX_LEN and for an unwritten extent this limit is
     * EXT_UNWRITTEN_MAX_LEN.
     */
    if (map->m_len > EXT_INIT_MAX_LEN &&
        !(flags & EXT4_GET_BLOCKS_UNWRIT_EXT))
        map->m_len = EXT_INIT_MAX_LEN;
    else if (map->m_len > EXT_UNWRITTEN_MAX_LEN &&
         (flags & EXT4_GET_BLOCKS_UNWRIT_EXT))
        map->m_len = EXT_UNWRITTEN_MAX_LEN;

    /* Check if we can really insert (m_lblk)::(m_lblk + m_len) extent */
    newex.ee_len = cpu_to_le16(map->m_len);
    err = ext4_ext_check_overlap(sbi, inode, &newex, path);
    if (err)
        allocated = ext4_ext_get_actual_len(&newex);
    else
        allocated = map->m_len;

    /* allocate new block */
    ar.inode = inode;
    ar.goal = ext4_ext_find_goal(inode, path, map->m_lblk);
    ar.logical = map->m_lblk;
    /*
     * We calculate the offset from the beginning of the cluster
     * for the logical block number, since when we allocate a
     * physical cluster, the physical block should start at the
     * same offset from the beginning of the cluster.  This is
     * needed so that future calls to get_implied_cluster_alloc()
     * work correctly.
     */
    offset = EXT4_LBLK_COFF(sbi, map->m_lblk);
    ar.len = EXT4_NUM_B2C(sbi, offset+allocated);
    ar.goal -= offset;
    ar.logical -= offset;
    if (S_ISREG(inode->i_mode))
        ar.flags = EXT4_MB_HINT_DATA;
    else
        /* disable in-core preallocation for non-regular files */
        ar.flags = 0;
    if (flags & EXT4_GET_BLOCKS_NO_NORMALIZE)
        ar.flags |= EXT4_MB_HINT_NOPREALLOC;
    if (flags & EXT4_GET_BLOCKS_DELALLOC_RESERVE)
        ar.flags |= EXT4_MB_DELALLOC_RESERVED;
    if (flags & EXT4_GET_BLOCKS_METADATA_NOFAIL)
        ar.flags |= EXT4_MB_USE_RESERVED;
    newblock = ext4_mb_new_blocks(handle, &ar, &err);
    if (!newblock)
        goto out2;
    ext_debug("allocate new block: goal %llu, found %llu/%u\n",
          ar.goal, newblock, allocated);
    free_on_err = 1;
    allocated_clusters = ar.len;
    ar.len = EXT4_C2B(sbi, ar.len) - offset;
    if (ar.len > allocated)
        ar.len = allocated;

got_allocated_blocks:
    /* try to insert new extent into found leaf and return */
    ext4_ext_store_pblock(&newex, newblock + offset);
    newex.ee_len = cpu_to_le16(ar.len);
    /* Mark unwritten */
    if (flags & EXT4_GET_BLOCKS_UNWRIT_EXT){
        ext4_ext_mark_unwritten(&newex);
        map->m_flags |= EXT4_MAP_UNWRITTEN;
        /*
         * io_end structure was created for every IO write to an
         * unwritten extent. To avoid unnecessary conversion,
         * here we flag the IO that really needs the conversion.
         * For non asycn direct IO case, flag the inode state
         * that we need to perform conversion when IO is done.
         */
        if (flags & EXT4_GET_BLOCKS_PRE_IO)
            set_unwritten = 1;
    }

    err = 0;
    if ((flags & EXT4_GET_BLOCKS_KEEP_SIZE) == 0)
        err = check_eofblocks_fl(handle, inode, map->m_lblk,
                     path, ar.len);
    if (!err)
        err = ext4_ext_insert_extent(handle, inode, &path,
                         &newex, flags);

    if (!err && set_unwritten) {
        if (io)
            ext4_set_io_unwritten_flag(inode, io);
        else
            ext4_set_inode_state(inode,
                         EXT4_STATE_DIO_UNWRITTEN);
    }

    if (err && free_on_err) {
        int fb_flags = flags & EXT4_GET_BLOCKS_DELALLOC_RESERVE ?
            EXT4_FREE_BLOCKS_NO_QUOT_UPDATE : 0;
        /* free data blocks we just allocated */
        /* not a good idea to call discard here directly,
         * but otherwise we'd need to call it every free() */
        ext4_discard_preallocations(inode);
        ext4_free_blocks(handle, inode, NULL, newblock,
                 EXT4_C2B(sbi, allocated_clusters), fb_flags);
        goto out2;
    }

    /* previous routine could use block we allocated */
    newblock = ext4_ext_pblock(&newex);
    allocated = ext4_ext_get_actual_len(&newex);
    if (allocated > map->m_len)
        allocated = map->m_len;
    map->m_flags |= EXT4_MAP_NEW;

    /*
     * Update reserved blocks/metadata blocks after successful
     * block allocation which had been deferred till now.
     */
    if (flags & EXT4_GET_BLOCKS_DELALLOC_RESERVE) {
        unsigned int reserved_clusters;
        /*
         * Check how many clusters we had reserved this allocated range
         */
        reserved_clusters = get_reserved_cluster_alloc(inode,
                        map->m_lblk, allocated);
        if (!map_from_cluster) {
            BUG_ON(allocated_clusters < reserved_clusters);
            if (reserved_clusters < allocated_clusters) {
                struct ext4_inode_info *ei = EXT4_I(inode);
                int reservation = allocated_clusters -
                          reserved_clusters;
                /*
                 * It seems we claimed few clusters outside of
                 * the range of this allocation. We should give
                 * it back to the reservation pool. This can
                 * happen in the following case:
                 *
                 * * Suppose s_cluster_ratio is 4 (i.e., each
                 *   cluster has 4 blocks. Thus, the clusters
                 *   are [0-3],[4-7],[8-11]...
                 * * First comes delayed allocation write for
                 *   logical blocks 10 & 11. Since there were no
                 *   previous delayed allocated blocks in the
                 *   range [8-11], we would reserve 1 cluster
                 *   for this write.
                 * * Next comes write for logical blocks 3 to 8.
                 *   In this case, we will reserve 2 clusters
                 *   (for [0-3] and [4-7]; and not for [8-11] as
                 *   that range has a delayed allocated blocks.
                 *   Thus total reserved clusters now becomes 3.
                 * * Now, during the delayed allocation writeout
                 *   time, we will first write blocks [3-8] and
                 *   allocate 3 clusters for writing these
                 *   blocks. Also, we would claim all these
                 *   three clusters above.
                 * * Now when we come here to writeout the
                 *   blocks [10-11], we would expect to claim
                 *   the reservation of 1 cluster we had made
                 *   (and we would claim it since there are no
                 *   more delayed allocated blocks in the range
                 *   [8-11]. But our reserved cluster count had
                 *   already gone to 0.
                 *
                 *   Thus, at the step 4 above when we determine
                 *   that there are still some unwritten delayed
                 *   allocated blocks outside of our current
                 *   block range, we should increment the
                 *   reserved clusters count so that when the
                 *   remaining blocks finally gets written, we
                 *   could claim them.
                 */
                dquot_reserve_block(inode,
                        EXT4_C2B(sbi, reservation));
                spin_lock(&ei->i_block_reservation_lock);
                ei->i_reserved_data_blocks += reservation;
                spin_unlock(&ei->i_block_reservation_lock);
            }
            /*
             * We will claim quota for all newly allocated blocks.
             * We're updating the reserved space *after* the
             * correction above so we do not accidentally free
             * all the metadata reservation because we might
             * actually need it later on.
             */
            ext4_da_update_reserve_space(inode, allocated_clusters,
                            1);
        }
    }

    /*
     * Cache the extent and update transaction to commit on fdatasync only
     * when it is _not_ an unwritten extent.
     */
    if ((flags & EXT4_GET_BLOCKS_UNWRIT_EXT) == 0)
        ext4_update_inode_fsync_trans(handle, inode, 1);
    else
        ext4_update_inode_fsync_trans(handle, inode, 0);
out:
    if (allocated > map->m_len)
        allocated = map->m_len;
    ext4_ext_show_leaf(inode, path);
    map->m_flags |= EXT4_MAP_MAPPED;
    map->m_pblk = newblock;
    map->m_len = allocated;
out2:
    ext4_ext_drop_refs(path);
    kfree(path);

    trace_ext4_ext_map_blocks_exit(inode, flags, map,
                       err ? err : allocated);
    return err ? err : allocated;
}
```