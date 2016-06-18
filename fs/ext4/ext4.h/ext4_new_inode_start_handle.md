ext4_new_inode_start_handle
========================================

path: fs/ext4/ext4.h
```
#define ext4_new_inode_start_handle(dir, mode, qstr, goal, owner, \
                    type, nblocks)            \
    __ext4_new_inode(NULL, (dir), (mode), (qstr), (goal), (owner), \
             (type), __LINE__, (nblocks))
```

__ext4_new_inode
----------------------------------------

https://github.com/novelinux/linux-4.x.y/blob/master/fs/ext4/ialloc.c/__ext4_new_inode.md
