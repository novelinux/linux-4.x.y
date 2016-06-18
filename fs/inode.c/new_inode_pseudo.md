new_inode_pseudo
========================================

path: fs/inode.c
```
/**
 *    new_inode_pseudo     - obtain an inode
 *    @sb: superblock
 *
 *    Allocates a new inode for given superblock.
 *    Inode wont be chained in superblock s_inodes list
 *    This means :
 *    - fs can't be unmount
 *    - quotas, fsnotify, writeback can't work
 */
struct inode *new_inode_pseudo(struct super_block *sb)
{
    struct inode *inode = alloc_inode(sb);

    if (inode) {
        spin_lock(&inode->i_lock);
        inode->i_state = 0;
        spin_unlock(&inode->i_lock);
        INIT_LIST_HEAD(&inode->i_sb_list);
    }
    return inode;
}
```

alloc_inode
----------------------------------------

https://github.com/novelinux/linux-4.x.y/blob/master/fs/inode.c
