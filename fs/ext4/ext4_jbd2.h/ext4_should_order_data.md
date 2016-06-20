ext4_should_order_data
========================================

path: fs/ext4/ext4_jbd2.h
```
static inline int ext4_should_order_data(struct inode *inode)
{
    return ext4_inode_journal_mode(inode) & EXT4_INODE_ORDERED_DATA_MODE;
}
```

ext4_inode_journal_mode
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/fs/ext4/ext4_jbd2.h/ext4_inode_journal_mode.md
