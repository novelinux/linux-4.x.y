ext4_begin_ordered_truncate
========================================

path: fs/ext4/inode.c
```
static inline int ext4_begin_ordered_truncate(struct inode *inode,
                          loff_t new_size)
{
    trace_ext4_begin_ordered_truncate(inode, new_size);

    /*
     * If jinode is zero, then we never opened the file for
     * writing, so there's no need to call
     * jbd2_journal_begin_ordered_truncate() since there's no
     * outstanding writes we need to flush.
     */
    if (!EXT4_I(inode)->jinode)
        return 0;
    return jbd2_journal_begin_ordered_truncate(EXT4_JOURNAL(inode),
                           EXT4_I(inode)->jinode,
                           new_size);
}
```

jbd2_journal_begin_ordered_truncate
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/fs/jbd2/transaction.c/jbd2_journal_begin_ordered_truncate.md
