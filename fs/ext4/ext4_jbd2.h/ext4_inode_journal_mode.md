ext4_inode_journal_mode
========================================

path: fs/ext4/ext4_jbd2.h
```
/*
 * Ext4 inode journal modes
 */
#define EXT4_INODE_JOURNAL_DATA_MODE    0x01 /* journal data mode */
#define EXT4_INODE_ORDERED_DATA_MODE    0x02 /* ordered data mode */
#define EXT4_INODE_WRITEBACK_DATA_MODE    0x04 /* writeback data mode */

static inline int ext4_inode_journal_mode(struct inode *inode)
{
    if (EXT4_JOURNAL(inode) == NULL)
        return EXT4_INODE_WRITEBACK_DATA_MODE;    /* writeback */
    /* We do not support data journalling with delayed allocation */
    if (!S_ISREG(inode->i_mode) ||
        test_opt(inode->i_sb, DATA_FLAGS) == EXT4_MOUNT_JOURNAL_DATA)
        return EXT4_INODE_JOURNAL_DATA_MODE;    /* journal data */
    if (ext4_test_inode_flag(inode, EXT4_INODE_JOURNAL_DATA) &&
        !test_opt(inode->i_sb, DELALLOC))
        return EXT4_INODE_JOURNAL_DATA_MODE;    /* journal data */
    if (test_opt(inode->i_sb, DATA_FLAGS) == EXT4_MOUNT_ORDERED_DATA)
        return EXT4_INODE_ORDERED_DATA_MODE;    /* ordered */
    if (test_opt(inode->i_sb, DATA_FLAGS) == EXT4_MOUNT_WRITEBACK_DATA)
        return EXT4_INODE_WRITEBACK_DATA_MODE;    /* writeback */
    else
        BUG();
}
```