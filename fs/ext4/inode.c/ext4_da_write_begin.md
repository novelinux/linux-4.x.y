ext4_da_write_begin
========================================

path: fs/ext4/inode.c
```
static int ext4_da_write_begin(struct file *file, struct address_space *mapping,
                   loff_t pos, unsigned len, unsigned flags,
                   struct page **pagep, void **fsdata)
{
    int ret, retries = 0;
    struct page *page;
    pgoff_t index;
    struct inode *inode = mapping->host;
    handle_t *handle;

    index = pos >> PAGE_CACHE_SHIFT;

    if (ext4_nonda_switch(inode->i_sb)) {
        *fsdata = (void *)FALL_BACK_TO_NONDELALLOC;
        return ext4_write_begin(file, mapping, pos,
                    len, flags, pagep, fsdata);
    }
    *fsdata = (void *)0;
    trace_ext4_da_write_begin(inode, pos, len, flags);

    if (ext4_test_inode_state(inode, EXT4_STATE_MAY_INLINE_DATA)) {
        ret = ext4_da_write_inline_data_begin(mapping, inode,
                              pos, len, flags,
                              pagep, fsdata);
        if (ret < 0)
            return ret;
        if (ret == 1)
            return 0;
    }

    /*
     * grab_cache_page_write_begin() can take a long time if the
     * system is thrashing due to memory pressure, or if the page
     * is being written back.  So grab it first before we start
     * the transaction handle.  This also allows us to allocate
     * the page (if needed) without using GFP_NOFS.
     */
retry_grab:
    page = grab_cache_page_write_begin(mapping, index, flags);
    if (!page)
        return -ENOMEM;
    unlock_page(page);

    /*
     * With delayed allocation, we don't log the i_disksize update
     * if there is delayed block allocation. But we still need
     * to journalling the i_disksize update if writes to the end
     * of file which has an already mapped buffer.
     */
retry_journal:
    handle = ext4_journal_start(inode, EXT4_HT_WRITE_PAGE,
                ext4_da_write_credits(inode, pos, len));
    if (IS_ERR(handle)) {
        page_cache_release(page);
        return PTR_ERR(handle);
    }

    lock_page(page);
    if (page->mapping != mapping) {
        /* The page got truncated from under us */
        unlock_page(page);
        page_cache_release(page);
        ext4_journal_stop(handle);
        goto retry_grab;
    }
    /* In case writeback began while the page was unlocked */
    wait_for_stable_page(page);

#ifdef CONFIG_EXT4_FS_ENCRYPTION
    ret = ext4_block_write_begin(page, pos, len,
                     ext4_da_get_block_prep);
#else
    ret = __block_write_begin(page, pos, len, ext4_da_get_block_prep);
#endif
    if (ret < 0) {
        unlock_page(page);
        ext4_journal_stop(handle);
        /*
         * block_write_begin may have instantiated a few blocks
         * outside i_size.  Trim these off again. Don't need
         * i_size_read because we hold i_mutex.
         */
        if (pos + len > inode->i_size)
            ext4_truncate_failed_write(inode);

        if (ret == -ENOSPC &&
            ext4_should_retry_alloc(inode->i_sb, &retries))
            goto retry_journal;

        page_cache_release(page);
        return ret;
    }

    *pagep = page;
    return ret;
}
```