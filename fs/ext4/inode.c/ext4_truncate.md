ext4_truncate
========================================

Comments
----------------------------------------

path: fs/ext4/inode.c
```
/*
 * ext4_truncate()
 *
 * We block out ext4_get_block() block instantiations across the entire
 * transaction, and VFS/VM ensures that ext4_truncate() cannot run
 * simultaneously on behalf of the same inode.
 *
 * As we work through the truncate and commit bits of it to the journal there
 * is one core, guiding principle: the file's tree must always be consistent on
 * disk.  We must be able to restart the truncate after a crash.
 *
 * The file's tree may be transiently inconsistent in memory (although it
 * probably isn't), but whenever we close off and commit a journal transaction,
 * the contents of (the filesystem + the journal) must be consistent and
 * restartable.  It's pretty simple, really: bottom up, right to left (although
 * left-to-right works OK too).
 *
 * Note that at recovery time, journal replay occurs *before* the restart of
 * truncate against the orphan inode list.
 *
 * The committed inode has the new, desired i_size (which is the same as
 * i_disksize in this case).  After a crash, ext4_orphan_cleanup() will see
 * that this inode's truncate did not complete and it will again call
 * ext4_truncate() to have another go.  So there will be instantiated blocks
 * to the right of the truncation point in a crashed ext4 filesystem.  But
 * that's fine - as long as they are linked from the inode, the post-crash
 * ext4_truncate() run will find them and release them.
 */
```

Arguments
----------------------------------------

```
void ext4_truncate(struct inode *inode)
{
    struct ext4_inode_info *ei = EXT4_I(inode);
    unsigned int credits;
    handle_t *handle;
    struct address_space *mapping = inode->i_mapping;

    /*
     * There is a possibility that we're either freeing the inode
     * or it's a completely new inode. In those cases we might not
     * have i_mutex locked because it's not necessary.
     */
    if (!(inode->i_state & (I_NEW|I_FREEING)))
        WARN_ON(!mutex_is_locked(&inode->i_mutex));
    trace_ext4_truncate_enter(inode);

    if (!ext4_can_truncate(inode))
        return;

    ext4_clear_inode_flag(inode, EXT4_INODE_EOFBLOCKS);

    if (inode->i_size == 0 && !test_opt(inode->i_sb, NO_AUTO_DA_ALLOC))
        ext4_set_inode_state(inode, EXT4_STATE_DA_ALLOC_CLOSE);

    if (ext4_has_inline_data(inode)) {
        int has_inline = 1;

        ext4_inline_data_truncate(inode, &has_inline);
        if (has_inline)
            return;
    }

    /* If we zero-out tail of the page, we have to create jinode for jbd2 */
    if (inode->i_size & (inode->i_sb->s_blocksize - 1)) {
        if (ext4_inode_attach_jinode(inode) < 0)
            return;
    }

    if (ext4_test_inode_flag(inode, EXT4_INODE_EXTENTS))
        credits = ext4_writepage_trans_blocks(inode);
    else
        credits = ext4_blocks_for_truncate(inode);
```

ext4_journal_start
----------------------------------------

```
    handle = ext4_journal_start(inode, EXT4_HT_TRUNCATE, credits);
    if (IS_ERR(handle)) {
        ext4_std_error(inode->i_sb, PTR_ERR(handle));
        return;
    }

    if (inode->i_size & (inode->i_sb->s_blocksize - 1))
        ext4_block_truncate_page(handle, mapping, inode->i_size);

    /*
     * We add the inode to the orphan list, so that if this
     * truncate spans multiple transactions, and we crash, we will
     * resume the truncate when the filesystem recovers.  It also
     * marks the inode dirty, to catch the new size.
     *
     * Implication: the file must always be in a sane, consistent
     * truncatable state while each transaction commits.
     */
    if (ext4_orphan_add(handle, inode))
        goto out_stop;

    down_write(&EXT4_I(inode)->i_data_sem);
```

ext4_discard_preallocations
----------------------------------------

```
    ext4_discard_preallocations(inode);
```

ext4_ext_truncate
----------------------------------------

```
    if (ext4_test_inode_flag(inode, EXT4_INODE_EXTENTS))
        ext4_ext_truncate(handle, inode);
    else
        ext4_ind_truncate(handle, inode);
```

https://github.com/novelinux/linux-4.x.y/tree/master/fs/ext4/extents.c/ext4_ext_truncate.md

ext4_handle_sync
----------------------------------------

```
    up_write(&ei->i_data_sem);

    if (IS_SYNC(inode))
        ext4_handle_sync(handle);

out_stop:
    /*
     * If this was a simple ftruncate() and the file will remain alive,
     * then we need to clear up the orphan record which we created above.
     * However, if this was a real unlink then we were called by
     * ext4_evict_inode(), and we allow that function to clean up the
     * orphan info for us.
     */
    if (inode->i_nlink)
        ext4_orphan_del(handle, inode);

    inode->i_mtime = inode->i_ctime = ext4_current_time(inode);
    ext4_mark_inode_dirty(handle, inode);
    ext4_journal_stop(handle);

    trace_ext4_truncate_exit(inode);
}
```