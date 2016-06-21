ext4_da_write_end
========================================

path: fs/ext4/inode.c
```
static int ext4_da_write_end(struct file *file,
                 struct address_space *mapping,
                 loff_t pos, unsigned len, unsigned copied,
                 struct page *page, void *fsdata)
{
    struct inode *inode = mapping->host;
    int ret = 0, ret2;
    handle_t *handle = ext4_journal_current_handle();
    loff_t new_i_size;
    unsigned long start, end;
    int write_mode = (int)(unsigned long)fsdata;

    if (write_mode == FALL_BACK_TO_NONDELALLOC)
        return ext4_write_end(file, mapping, pos,
                      len, copied, page, fsdata);

    trace_ext4_da_write_end(inode, pos, len, copied);
    start = pos & (PAGE_CACHE_SIZE - 1);
    end = start + copied - 1;

    /*
     * generic_write_end() will run mark_inode_dirty() if i_size
     * changes.  So let's piggyback the i_disksize mark_inode_dirty
     * into that.
     */
    new_i_size = pos + copied;
    if (copied && new_i_size > EXT4_I(inode)->i_disksize) {
        if (ext4_has_inline_data(inode) ||
            ext4_da_should_update_i_disksize(page, end)) {
            ext4_update_i_disksize(inode, new_i_size);
            /* We need to mark inode dirty even if
             * new_i_size is less that inode->i_size
             * bu greater than i_disksize.(hint delalloc)
             */
            ext4_mark_inode_dirty(handle, inode);
        }
    }

    if (write_mode != CONVERT_INLINE_DATA &&
        ext4_test_inode_state(inode, EXT4_STATE_MAY_INLINE_DATA) &&
        ext4_has_inline_data(inode))
        ret2 = ext4_da_write_inline_data_end(inode, pos, len, copied,
                             page);
    else
        ret2 = generic_write_end(file, mapping, pos, len, copied,
                            page, fsdata);

    copied = ret2;
    if (ret2 < 0)
        ret = ret2;
    ret2 = ext4_journal_stop(handle);
    if (!ret)
        ret = ret2;

    return ret ? ret : copied;
}
```