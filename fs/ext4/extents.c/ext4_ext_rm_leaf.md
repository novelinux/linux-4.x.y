ext4_ext_rm_leaf
========================================

Arguments
----------------------------------------

path: fs/ext4/extents.c
```
/*
 * ext4_ext_rm_leaf() Removes the extents associated with the
 * blocks appearing between "start" and "end".  Both "start"
 * and "end" must appear in the same extent or EIO is returned.
 *
 * @handle: The journal handle
 * @inode:  The files inode
 * @path:   The path to the leaf
 * @partial_cluster: The cluster which we'll have to free if all extents
 *                   has been released from it.  However, if this value is
 *                   negative, it's a cluster just to the right of the
 *                   punched region and it must not be freed.
 * @start:  The first block to remove
 * @end:   The last block to remove
 */
static int
ext4_ext_rm_leaf(handle_t *handle, struct inode *inode,
         struct ext4_ext_path *path,
         long long *partial_cluster,
         ext4_lblk_t start, ext4_lblk_t end)
{
    struct ext4_sb_info *sbi = EXT4_SB(inode->i_sb);
    int err = 0, correct_index = 0;
    int depth = ext_depth(inode), credits;
    struct ext4_extent_header *eh;
    ext4_lblk_t a, b;
    unsigned num;
    ext4_lblk_t ex_ee_block;
    unsigned short ex_ee_len;
    unsigned unwritten = 0;
    struct ext4_extent *ex;
    ext4_fsblk_t pblk;

    /* the header must be checked already in ext4_ext_remove_space() */
    ext_debug("truncate since %u in leaf to %u\n", start, end);
    if (!path[depth].p_hdr)
        path[depth].p_hdr = ext_block_hdr(path[depth].p_bh);
    eh = path[depth].p_hdr;
    if (unlikely(path[depth].p_hdr == NULL)) {
        EXT4_ERROR_INODE(inode, "path[%d].p_hdr == NULL", depth);
        return -EIO;
    }
    /* find where to start removing */
    ex = path[depth].p_ext;
    if (!ex)
        ex = EXT_LAST_EXTENT(eh);

    ex_ee_block = le32_to_cpu(ex->ee_block);
    ex_ee_len = ext4_ext_get_actual_len(ex);

    trace_ext4_ext_rm_leaf(inode, start, ex, *partial_cluster);
```

```
    while (ex >= EXT_FIRST_EXTENT(eh) &&
            ex_ee_block + ex_ee_len > start) {

        if (ext4_ext_is_unwritten(ex))
            unwritten = 1;
        else
            unwritten = 0;

        ext_debug("remove ext %u:[%d]%d\n", ex_ee_block,
              unwritten, ex_ee_len);
        path[depth].p_ext = ex;

        a = ex_ee_block > start ? ex_ee_block : start;
        b = ex_ee_block+ex_ee_len - 1 < end ?
            ex_ee_block+ex_ee_len - 1 : end;

        ext_debug("  border %u:%u\n", a, b);

        /* If this extent is beyond the end of the hole, skip it */
        if (end < ex_ee_block) {
            /*
             * We're going to skip this extent and move to another,
             * so note that its first cluster is in use to avoid
             * freeing it when removing blocks.  Eventually, the
             * right edge of the truncated/punched region will
             * be just to the left.
             */
            if (sbi->s_cluster_ratio > 1) {
                pblk = ext4_ext_pblock(ex);
                *partial_cluster =
                    -(long long) EXT4_B2C(sbi, pblk);
            }
            ex--;
            ex_ee_block = le32_to_cpu(ex->ee_block);
            ex_ee_len = ext4_ext_get_actual_len(ex);
            continue;
        } else if (b != ex_ee_block + ex_ee_len - 1) {
            EXT4_ERROR_INODE(inode,
                     "can not handle truncate %u:%u "
                     "on extent %u:%u",
                     start, end, ex_ee_block,
                     ex_ee_block + ex_ee_len - 1);
            err = -EIO;
            goto out;
        } else if (a != ex_ee_block) {
            /* remove tail of the extent */
            num = a - ex_ee_block;
        } else {
            /* remove whole extent: excellent! */
            num = 0;
        }
        /*
         * 3 for leaf, sb, and inode plus 2 (bmap and group
         * descriptor) for each block group; assume two block
         * groups plus ex_ee_len/blocks_per_block_group for
         * the worst case
         */
        credits = 7 + 2*(ex_ee_len/EXT4_BLOCKS_PER_GROUP(inode->i_sb));
        if (ex == EXT_FIRST_EXTENT(eh)) {
            correct_index = 1;
            credits += (ext_depth(inode)) + 1;
        }
        credits += EXT4_MAXQUOTAS_TRANS_BLOCKS(inode->i_sb);

        err = ext4_ext_truncate_extend_restart(handle, inode, credits);
        if (err)
            goto out;

        err = ext4_ext_get_access(handle, inode, path + depth);
        if (err)
            goto out;

        err = ext4_remove_blocks(handle, inode, ex, partial_cluster,
                     a, b);
        if (err)
            goto out;

        if (num == 0)
            /* this extent is removed; mark slot entirely unused */
            ext4_ext_store_pblock(ex, 0);

        ex->ee_len = cpu_to_le16(num);
        /*
         * Do not mark unwritten if all the blocks in the
         * extent have been removed.
         */
        if (unwritten && num)
            ext4_ext_mark_unwritten(ex);
        /*
         * If the extent was completely released,
         * we need to remove it from the leaf
         */
        if (num == 0) {
            if (end != EXT_MAX_BLOCKS - 1) {
                /*
                 * For hole punching, we need to scoot all the
                 * extents up when an extent is removed so that
                 * we dont have blank extents in the middle
                 */
                memmove(ex, ex+1, (EXT_LAST_EXTENT(eh) - ex) *
                    sizeof(struct ext4_extent));

                /* Now get rid of the one at the end */
                memset(EXT_LAST_EXTENT(eh), 0,
                    sizeof(struct ext4_extent));
            }
            le16_add_cpu(&eh->eh_entries, -1);
        }

        err = ext4_ext_dirty(handle, inode, path + depth);
        if (err)
            goto out;

        ext_debug("new extent: %u:%u:%llu\n", ex_ee_block, num,
                ext4_ext_pblock(ex));
        ex--;
        ex_ee_block = le32_to_cpu(ex->ee_block);
        ex_ee_len = ext4_ext_get_actual_len(ex);
    }

    if (correct_index && eh->eh_entries)
        err = ext4_ext_correct_indexes(handle, inode, path);

    /*
     * If there's a partial cluster and at least one extent remains in
     * the leaf, free the partial cluster if it isn't shared with the
     * current extent.  If it is shared with the current extent
     * we zero partial_cluster because we've reached the start of the
     * truncated/punched region and we're done removing blocks.
     */
    if (*partial_cluster > 0 && ex >= EXT_FIRST_EXTENT(eh)) {
        pblk = ext4_ext_pblock(ex) + ex_ee_len - 1;
        if (*partial_cluster != (long long) EXT4_B2C(sbi, pblk)) {
            ext4_free_blocks(handle, inode, NULL,
                     EXT4_C2B(sbi, *partial_cluster),
                     sbi->s_cluster_ratio,
                     get_default_free_blocks_flags(inode));
        }
        *partial_cluster = 0;
    }

    /* if this leaf is free, then we should
     * remove it from index block above */
    if (err == 0 && eh->eh_entries == 0 && path[depth].p_bh != NULL)
        err = ext4_ext_rm_idx(handle, inode, path, depth);

out:
    return err;
}
```