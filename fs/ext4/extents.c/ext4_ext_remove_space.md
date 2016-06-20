ext4_ext_remove_space
========================================

Arguments
----------------------------------------

path: fs/ext4/extents.c
```
int ext4_ext_remove_space(struct inode *inode, ext4_lblk_t start,
              ext4_lblk_t end)
{
    struct ext4_sb_info *sbi = EXT4_SB(inode->i_sb);
    int depth = ext_depth(inode);
    struct ext4_ext_path *path = NULL;
    long long partial_cluster = 0;
    handle_t *handle;
    int i = 0, err = 0;

    ext_debug("truncate since %u to %u\n", start, end);
```

ext4_journal_start
----------------------------------------

```
    /* probably first extent we're gonna free will be last in block */
    handle = ext4_journal_start(inode, EXT4_HT_TRUNCATE, depth + 1);
    if (IS_ERR(handle))
        return PTR_ERR(handle);
```

again
----------------------------------------

### (end < EXT_MAX_BLOCKS - 1)

```
again:
    trace_ext4_ext_remove_space(inode, start, end, depth);

    /*
     * Check if we are removing extents inside the extent tree. If that
     * is the case, we are going to punch a hole inside the extent tree
     * so we have to check whether we need to split the extent covering
     * the last block to remove so we can easily remove the part of it
     * in ext4_ext_rm_leaf().
     */
    if (end < EXT_MAX_BLOCKS - 1) {
        struct ext4_extent *ex;
        ext4_lblk_t ee_block, ex_end, lblk;
        ext4_fsblk_t pblk;

        /* find extent for or closest extent to this block */
        path = ext4_find_extent(inode, end, NULL, EXT4_EX_NOCACHE);
        if (IS_ERR(path)) {
            ext4_journal_stop(handle);
            return PTR_ERR(path);
        }
        depth = ext_depth(inode);
        /* Leaf not may not exist only if inode has no blocks at all */
        ex = path[depth].p_ext;
        if (!ex) {
            if (depth) {
                EXT4_ERROR_INODE(inode,
                         "path[%d].p_hdr == NULL",
                         depth);
                err = -EIO;
            }
            goto out;
        }

        ee_block = le32_to_cpu(ex->ee_block);
        ex_end = ee_block + ext4_ext_get_actual_len(ex) - 1;

        /*
         * See if the last block is inside the extent, if so split
         * the extent at 'end' block so we can easily remove the
         * tail of the first part of the split extent in
         * ext4_ext_rm_leaf().
         */
        if (end >= ee_block && end < ex_end) {

            /*
             * If we're going to split the extent, note that
             * the cluster containing the block after 'end' is
             * in use to avoid freeing it when removing blocks.
             */
            if (sbi->s_cluster_ratio > 1) {
                pblk = ext4_ext_pblock(ex) + end - ee_block + 2;
                partial_cluster =
                    -(long long) EXT4_B2C(sbi, pblk);
            }

            /*
             * Split the extent in two so that 'end' is the last
             * block in the first new extent. Also we should not
             * fail removing space due to ENOSPC so try to use
             * reserved block if that happens.
             */
            err = ext4_force_split_extent_at(handle, inode, &path,
                             end + 1, 1);
            if (err < 0)
                goto out;

        } else if (sbi->s_cluster_ratio > 1 && end >= ex_end) {
            /*
             * If there's an extent to the right its first cluster
             * contains the immediate right boundary of the
             * truncated/punched region.  Set partial_cluster to
             * its negative value so it won't be freed if shared
             * with the current extent.  The end < ee_block case
             * is handled in ext4_ext_rm_leaf().
             */
            lblk = ex_end + 1;
            err = ext4_ext_search_right(inode, path, &lblk, &pblk,
                            &ex);
            if (err)
                goto out;
            if (pblk)
                partial_cluster =
                    -(long long) EXT4_B2C(sbi, pblk);
        }
    }
```

```
    /*
     * We start scanning from right side, freeing all the blocks
     * after i_size and walking into the tree depth-wise.
     */
    depth = ext_depth(inode);
    if (path) {
        int k = i = depth;
        while (--k > 0)
            path[k].p_block =
                le16_to_cpu(path[k].p_hdr->eh_entries)+1;
    } else {
        path = kzalloc(sizeof(struct ext4_ext_path) * (depth + 1),
                   GFP_NOFS);
        if (path == NULL) {
            ext4_journal_stop(handle);
            return -ENOMEM;
        }
        path[0].p_maxdepth = path[0].p_depth = depth;
        path[0].p_hdr = ext_inode_hdr(inode);
        i = 0;

        if (ext4_ext_check(inode, path[0].p_hdr, depth, 0)) {
            err = -EIO;
            goto out;
        }
    }
    err = 0;
```

```
    while (i >= 0 && err == 0) {
        if (i == depth) {
            /* this is leaf block */
            err = ext4_ext_rm_leaf(handle, inode, path,
                           &partial_cluster, start,
                           end);
            /* root level has p_bh == NULL, brelse() eats this */
            brelse(path[i].p_bh);
            path[i].p_bh = NULL;
            i--;
            continue;
        }

        /* this is index block */
        if (!path[i].p_hdr) {
            ext_debug("initialize header\n");
            path[i].p_hdr = ext_block_hdr(path[i].p_bh);
        }

        if (!path[i].p_idx) {
            /* this level hasn't been touched yet */
            path[i].p_idx = EXT_LAST_INDEX(path[i].p_hdr);
            path[i].p_block = le16_to_cpu(path[i].p_hdr->eh_entries)+1;
            ext_debug("init index ptr: hdr 0x%p, num %d\n",
                  path[i].p_hdr,
                  le16_to_cpu(path[i].p_hdr->eh_entries));
        } else {
            /* we were already here, see at next index */
            path[i].p_idx--;
        }

        ext_debug("level %d - index, first 0x%p, cur 0x%p\n",
                i, EXT_FIRST_INDEX(path[i].p_hdr),
                path[i].p_idx);
        if (ext4_ext_more_to_rm(path + i)) {
            struct buffer_head *bh;
            /* go to the next level */
            ext_debug("move to level %d (block %llu)\n",
                  i + 1, ext4_idx_pblock(path[i].p_idx));
            memset(path + i + 1, 0, sizeof(*path));
            bh = read_extent_tree_block(inode,
                ext4_idx_pblock(path[i].p_idx), depth - i - 1,
                EXT4_EX_NOCACHE);
            if (IS_ERR(bh)) {
                /* should we reset i_size? */
                err = PTR_ERR(bh);
                break;
            }
            /* Yield here to deal with large extent trees.
             * Should be a no-op if we did IO above. */
            cond_resched();
            if (WARN_ON(i + 1 > depth)) {
                err = -EIO;
                break;
            }
            path[i + 1].p_bh = bh;

            /* save actual number of indexes since this
             * number is changed at the next iteration */
            path[i].p_block = le16_to_cpu(path[i].p_hdr->eh_entries);
            i++;
        } else {
            /* we finished processing this index, go up */
            if (path[i].p_hdr->eh_entries == 0 && i > 0) {
                /* index is empty, remove it;
                 * handle must be already prepared by the
                 * truncatei_leaf() */
                err = ext4_ext_rm_idx(handle, inode, path, i);
            }
            /* root level has p_bh == NULL, brelse() eats this */
            brelse(path[i].p_bh);
            path[i].p_bh = NULL;
            i--;
            ext_debug("return to level %d\n", i);
        }
    }

    trace_ext4_ext_remove_space_done(inode, start, end, depth,
            partial_cluster, path->p_hdr->eh_entries);

    /*
     * If we still have something in the partial cluster and we have removed
     * even the first extent, then we should free the blocks in the partial
     * cluster as well.  (This code will only run when there are no leaves
     * to the immediate left of the truncated/punched region.)
     */
    if (partial_cluster > 0 && err == 0) {
        /* don't zero partial_cluster since it's not used afterwards */
        ext4_free_blocks(handle, inode, NULL,
                 EXT4_C2B(sbi, partial_cluster),
                 sbi->s_cluster_ratio,
                 get_default_free_blocks_flags(inode));
    }

    /* TODO: flexible tree reduction should be here */
    if (path->p_hdr->eh_entries == 0) {
        /*
         * truncate to zero freed all the tree,
         * so we need to correct eh_depth
         */
        err = ext4_ext_get_access(handle, inode, path);
        if (err == 0) {
            ext_inode_hdr(inode)->eh_depth = 0;
            ext_inode_hdr(inode)->eh_max =
                cpu_to_le16(ext4_ext_space_root(inode, 0));
            err = ext4_ext_dirty(handle, inode, path);
        }
    }
out:
    ext4_ext_drop_refs(path);
    kfree(path);
    path = NULL;
    if (err == -EAGAIN)
        goto again;
    ext4_journal_stop(handle);

    return err;
}
```