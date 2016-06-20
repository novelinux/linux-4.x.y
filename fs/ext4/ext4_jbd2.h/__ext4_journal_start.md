__ext4_journal_start
========================================

path: fs/ext4/ext4_jbd2.h
```
static inline handle_t *__ext4_journal_start(struct inode *inode,
                         unsigned int line, int type,
                         int blocks, int rsv_blocks)
{
    return __ext4_journal_start_sb(inode->i_sb, line, type, blocks,
                       rsv_blocks);
}
```

__ext4_journal_start_sb
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/fs/ext4/ext4_jbd2.c/__ext4_journal_start_sb.md
