ext4_journal_start
========================================

path: fs/ext4/ext4_jbd2.h
```
#define ext4_journal_start(inode, type, nblocks)            \
    __ext4_journal_start((inode), __LINE__, (type), (nblocks), 0)
```

__ext4_journal_start
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/fs/ext4/ext4_jbd2.h/__ext4_journal_start.md
