__ext4_new_inode
========================================

Comments
----------------------------------------

path: fs/ext4/ialloc.c
```
/*
 * There are two policies for allocating an inode.  If the new inode is
 * a directory, then a forward search is made for a block group with both
 * free space and a low directory-to-inode ratio; if that fails, then of
 * the groups with above-average free space, that group with the fewest
 * directories already is chosen.
 *
 * For other inodes, search forward from the parent directory's block
 * group to find a free inode.
 */
```

Arguments
----------------------------------------

```
struct inode *__ext4_new_inode(handle_t *handle, struct inode *dir,
                   umode_t mode, const struct qstr *qstr,
                   __u32 goal, uid_t *owner, int handle_type,
                   unsigned int line_no, int nblocks)
{
    struct super_block *sb;
    struct buffer_head *inode_bitmap_bh = NULL;
    struct buffer_head *group_desc_bh;
    ext4_group_t ngroups, group = 0;
    unsigned long ino = 0;
    struct inode *inode;
    struct ext4_group_desc *gdp = NULL;
    struct ext4_inode_info *ei;
    struct ext4_sb_info *sbi;
    int ret2, err;
    struct inode *ret;
    ext4_group_t i;
    ext4_group_t flex_group;
    struct ext4_group_info *grp;
    int encrypt = 0;

    /* Cannot create files in a deleted directory */
    if (!dir || !dir->i_nlink)
        return ERR_PTR(-EPERM);
```

ext4_encrypted_inode
----------------------------------------

```
    if ((ext4_encrypted_inode(dir) ||
         DUMMY_ENCRYPTION_ENABLED(EXT4_SB(dir->i_sb))) &&
        (S_ISREG(mode) || S_ISDIR(mode) || S_ISLNK(mode))) {
        err = ext4_get_encryption_info(dir);
        if (err)
            return ERR_PTR(err);
        if (ext4_encryption_info(dir) == NULL)
            return ERR_PTR(-EPERM);
        if (!handle)
            nblocks += EXT4_DATA_TRANS_BLOCKS(dir->i_sb);
        encrypt = 1;
    }
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/ext4/ext4_encrypted_inode.md

ext4_get_groups_count
----------------------------------------

```
    sb = dir->i_sb;
    ngroups = ext4_get_groups_count(sb);
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/ext4/ext4.h/ext4_get_groups_count.md

new_inode
----------------------------------------

```
    trace_ext4_request_inode(dir, mode);
    inode = new_inode(sb);
    if (!inode)
        return ERR_PTR(-ENOMEM);
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/inode.c/new_inode.md

Initialize to inode
----------------------------------------

```
    ei = EXT4_I(inode);
    sbi = EXT4_SB(sb);

    /*
     * Initalize owners and quota early so that we don't have to account
     * for quota initialization worst case in standard inode creating
     * transaction
     */
    if (owner) {
        inode->i_mode = mode;
        i_uid_write(inode, owner[0]);
        i_gid_write(inode, owner[1]);
    } else if (test_opt(sb, GRPID)) {
        inode->i_mode = mode;
        inode->i_uid = current_fsuid();
        inode->i_gid = dir->i_gid;
    } else
        inode_init_owner(inode, dir, mode);

    if (EXT4_HAS_RO_COMPAT_FEATURE(sb, EXT4_FEATURE_RO_COMPAT_PROJECT) &&
        ext4_test_inode_flag(dir, EXT4_INODE_PROJINHERIT))
        ei->i_projid = EXT4_I(dir)->i_projid;
    else
        ei->i_projid = make_kprojid(&init_user_ns, EXT4_DEF_PROJID);

    err = dquot_initialize(inode);
    if (err)
        goto out;

    if (!goal)
        goal = sbi->s_inode_goal;

    if (goal && goal <= le32_to_cpu(sbi->s_es->s_inodes_count)) {
        group = (goal - 1) / EXT4_INODES_PER_GROUP(sb);
        ino = (goal - 1) % EXT4_INODES_PER_GROUP(sb);
        ret2 = 0;
        goto got_group;
    }

    if (S_ISDIR(mode))
        ret2 = find_group_orlov(sb, dir, &group, mode, qstr);
    else
        ret2 = find_group_other(sb, dir, &group, mode);

got_group:
    EXT4_I(dir)->i_last_alloc_group = group;
    err = -ENOSPC;
    if (ret2 == -1)
        goto out;

    /*
     * Normally we will only go through one pass of this loop,
     * unless we get unlucky and it turns out the group we selected
     * had its last inode grabbed by someone else.
     */
    for (i = 0; i < ngroups; i++, ino = 0) {
        err = -EIO;

        gdp = ext4_get_group_desc(sb, group, &group_desc_bh);
        if (!gdp)
            goto out;

        /*
         * Check free inodes count before loading bitmap.
         */
        if (ext4_free_inodes_count(sb, gdp) == 0) {
            if (++group == ngroups)
                group = 0;
            continue;
        }

        grp = ext4_get_group_info(sb, group);
        /* Skip groups with already-known suspicious inode tables */
        if (EXT4_MB_GRP_IBITMAP_CORRUPT(grp)) {
            if (++group == ngroups)
                group = 0;
            continue;
        }

        brelse(inode_bitmap_bh);
        inode_bitmap_bh = ext4_read_inode_bitmap(sb, group);
        /* Skip groups with suspicious inode tables */
        if (EXT4_MB_GRP_IBITMAP_CORRUPT(grp) ||
            IS_ERR(inode_bitmap_bh)) {
            inode_bitmap_bh = NULL;
            if (++group == ngroups)
                group = 0;
            continue;
        }

repeat_in_this_group:
        ino = ext4_find_next_zero_bit((unsigned long *)
                          inode_bitmap_bh->b_data,
                          EXT4_INODES_PER_GROUP(sb), ino);
        if (ino >= EXT4_INODES_PER_GROUP(sb))
            goto next_group;
        if (group == 0 && (ino+1) < EXT4_FIRST_INO(sb)) {
            ext4_error(sb, "reserved inode found cleared - "
                   "inode=%lu", ino + 1);
            continue;
        }
        if ((EXT4_SB(sb)->s_journal == NULL) &&
            recently_deleted(sb, group, ino)) {
            ino++;
            goto next_inode;
        }
        if (!handle) {
            BUG_ON(nblocks <= 0);
            handle = __ext4_journal_start_sb(dir->i_sb, line_no,
                             handle_type, nblocks,
                             0);
            if (IS_ERR(handle)) {
                err = PTR_ERR(handle);
                ext4_std_error(sb, err);
                goto out;
            }
        }
        BUFFER_TRACE(inode_bitmap_bh, "get_write_access");
        err = ext4_journal_get_write_access(handle, inode_bitmap_bh);
        if (err) {
            ext4_std_error(sb, err);
            goto out;
        }
        ext4_lock_group(sb, group);
        ret2 = ext4_test_and_set_bit(ino, inode_bitmap_bh->b_data);
        ext4_unlock_group(sb, group);
        ino++;        /* the inode bitmap is zero-based */
        if (!ret2)
            goto got; /* we grabbed the inode! */
next_inode:
        if (ino < EXT4_INODES_PER_GROUP(sb))
            goto repeat_in_this_group;
next_group:
        if (++group == ngroups)
            group = 0;
    }
    err = -ENOSPC;
    goto out;

got:
    BUFFER_TRACE(inode_bitmap_bh, "call ext4_handle_dirty_metadata");
    err = ext4_handle_dirty_metadata(handle, NULL, inode_bitmap_bh);
    if (err) {
        ext4_std_error(sb, err);
        goto out;
    }

    BUFFER_TRACE(group_desc_bh, "get_write_access");
    err = ext4_journal_get_write_access(handle, group_desc_bh);
    if (err) {
        ext4_std_error(sb, err);
        goto out;
    }

    /* We may have to initialize the block bitmap if it isn't already */
    if (ext4_has_group_desc_csum(sb) &&
        gdp->bg_flags & cpu_to_le16(EXT4_BG_BLOCK_UNINIT)) {
        struct buffer_head *block_bitmap_bh;

        block_bitmap_bh = ext4_read_block_bitmap(sb, group);
        if (IS_ERR(block_bitmap_bh)) {
            err = PTR_ERR(block_bitmap_bh);
            goto out;
        }
        BUFFER_TRACE(block_bitmap_bh, "get block bitmap access");
        err = ext4_journal_get_write_access(handle, block_bitmap_bh);
        if (err) {
            brelse(block_bitmap_bh);
            ext4_std_error(sb, err);
            goto out;
        }

        BUFFER_TRACE(block_bitmap_bh, "dirty block bitmap");
        err = ext4_handle_dirty_metadata(handle, NULL, block_bitmap_bh);

        /* recheck and clear flag under lock if we still need to */
        ext4_lock_group(sb, group);
        if (gdp->bg_flags & cpu_to_le16(EXT4_BG_BLOCK_UNINIT)) {
            gdp->bg_flags &= cpu_to_le16(~EXT4_BG_BLOCK_UNINIT);
            ext4_free_group_clusters_set(sb, gdp,
                ext4_free_clusters_after_init(sb, group, gdp));
            ext4_block_bitmap_csum_set(sb, group, gdp,
                           block_bitmap_bh);
            ext4_group_desc_csum_set(sb, group, gdp);
        }
        ext4_unlock_group(sb, group);
        brelse(block_bitmap_bh);

        if (err) {
            ext4_std_error(sb, err);
            goto out;
        }
    }

    /* Update the relevant bg descriptor fields */
    if (ext4_has_group_desc_csum(sb)) {
        int free;
        struct ext4_group_info *grp = ext4_get_group_info(sb, group);

        down_read(&grp->alloc_sem); /* protect vs itable lazyinit */
        ext4_lock_group(sb, group); /* while we modify the bg desc */
        free = EXT4_INODES_PER_GROUP(sb) -
            ext4_itable_unused_count(sb, gdp);
        if (gdp->bg_flags & cpu_to_le16(EXT4_BG_INODE_UNINIT)) {
            gdp->bg_flags &= cpu_to_le16(~EXT4_BG_INODE_UNINIT);
            free = 0;
        }
        /*
         * Check the relative inode number against the last used
         * relative inode number in this group. if it is greater
         * we need to update the bg_itable_unused count
         */
        if (ino > free)
            ext4_itable_unused_set(sb, gdp,
                    (EXT4_INODES_PER_GROUP(sb) - ino));
        up_read(&grp->alloc_sem);
    } else {
        ext4_lock_group(sb, group);
    }

    ext4_free_inodes_set(sb, gdp, ext4_free_inodes_count(sb, gdp) - 1);
    if (S_ISDIR(mode)) {
        ext4_used_dirs_set(sb, gdp, ext4_used_dirs_count(sb, gdp) + 1);
        if (sbi->s_log_groups_per_flex) {
            ext4_group_t f = ext4_flex_group(sbi, group);

            atomic_inc(&sbi->s_flex_groups[f].used_dirs);
        }
    }
    if (ext4_has_group_desc_csum(sb)) {
        ext4_inode_bitmap_csum_set(sb, group, gdp, inode_bitmap_bh,
                       EXT4_INODES_PER_GROUP(sb) / 8);
        ext4_group_desc_csum_set(sb, group, gdp);
    }
    ext4_unlock_group(sb, group);

    BUFFER_TRACE(group_desc_bh, "call ext4_handle_dirty_metadata");
    err = ext4_handle_dirty_metadata(handle, NULL, group_desc_bh);
    if (err) {
        ext4_std_error(sb, err);
        goto out;
    }

    percpu_counter_dec(&sbi->s_freeinodes_counter);
    if (S_ISDIR(mode))
        percpu_counter_inc(&sbi->s_dirs_counter);

    if (sbi->s_log_groups_per_flex) {
        flex_group = ext4_flex_group(sbi, group);
        atomic_dec(&sbi->s_flex_groups[flex_group].free_inodes);
    }

    inode->i_ino = ino + group * EXT4_INODES_PER_GROUP(sb);
    /* This is the optimal IO size (for stat), not the fs block size */
    inode->i_blocks = 0;
    inode->i_mtime = inode->i_atime = inode->i_ctime = ei->i_crtime =
                               ext4_current_time(inode);

    memset(ei->i_data, 0, sizeof(ei->i_data));
    ei->i_dir_start_lookup = 0;
    ei->i_disksize = 0;

    /* Don't inherit extent flag from directory, amongst others. */
    ei->i_flags =
        ext4_mask_flags(mode, EXT4_I(dir)->i_flags & EXT4_FL_INHERITED);
    ei->i_file_acl = 0;
    ei->i_dtime = 0;
    ei->i_block_group = group;
    ei->i_last_alloc_group = ~0;

    ext4_set_inode_flags(inode);
    if (IS_DIRSYNC(inode))
        ext4_handle_sync(handle);
    if (insert_inode_locked(inode) < 0) {
        /*
         * Likely a bitmap corruption causing inode to be allocated
         * twice.
         */
        err = -EIO;
        ext4_error(sb, "failed to insert inode %lu: doubly allocated?",
               inode->i_ino);
        goto out;
    }
    spin_lock(&sbi->s_next_gen_lock);
    inode->i_generation = sbi->s_next_generation++;
    spin_unlock(&sbi->s_next_gen_lock);

    /* Precompute checksum seed for inode metadata */
    if (ext4_has_metadata_csum(sb)) {
        __u32 csum;
        __le32 inum = cpu_to_le32(inode->i_ino);
        __le32 gen = cpu_to_le32(inode->i_generation);
        csum = ext4_chksum(sbi, sbi->s_csum_seed, (__u8 *)&inum,
                   sizeof(inum));
        ei->i_csum_seed = ext4_chksum(sbi, csum, (__u8 *)&gen,
                          sizeof(gen));
    }

    ext4_clear_state_flags(ei); /* Only relevant on 32-bit archs */
    ext4_set_inode_state(inode, EXT4_STATE_NEW);

    ei->i_extra_isize = EXT4_SB(sb)->s_want_extra_isize;
    ei->i_inline_off = 0;
    if (ext4_has_feature_inline_data(sb))
        ext4_set_inode_state(inode, EXT4_STATE_MAY_INLINE_DATA);
    ret = inode;
    err = dquot_alloc_inode(inode);
    if (err)
        goto fail_drop;

    err = ext4_init_acl(handle, inode, dir);
    if (err)
        goto fail_free_drop;

    err = ext4_init_security(handle, inode, dir, qstr);
    if (err)
        goto fail_free_drop;

    if (ext4_has_feature_extents(sb)) {
        /* set extent flag only for directory, file and normal symlink*/
        if (S_ISDIR(mode) || S_ISREG(mode) || S_ISLNK(mode)) {
            ext4_set_inode_flag(inode, EXT4_INODE_EXTENTS);
            ext4_ext_tree_init(handle, inode);
        }
    }

    if (ext4_handle_valid(handle)) {
        ei->i_sync_tid = handle->h_transaction->t_tid;
        ei->i_datasync_tid = handle->h_transaction->t_tid;
    }
```

ext4_inherit_context
----------------------------------------

```
    if (encrypt) {
        err = ext4_inherit_context(dir, inode);
        if (err)
            goto fail_free_drop;
    }
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/ext4/crypto_policy.c/ext4_inherit_context.md

ext4_mark_inode_dirty
----------------------------------------

```
    err = ext4_mark_inode_dirty(handle, inode);
    if (err) {
        ext4_std_error(sb, err);
        goto fail_free_drop;
    }

    ext4_debug("allocating inode %lu\n", inode->i_ino);
    trace_ext4_allocate_inode(inode, dir, mode);
    brelse(inode_bitmap_bh);
    return ret;

fail_free_drop:
    dquot_free_inode(inode);
fail_drop:
    clear_nlink(inode);
    unlock_new_inode(inode);
out:
    dquot_drop(inode);
    inode->i_flags |= S_NOQUOTA;
    iput(inode);
    brelse(inode_bitmap_bh);
    return ERR_PTR(err);
}
```
