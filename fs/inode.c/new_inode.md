new_inode
========================================

path: fs/inode.c
```
/**
 *    new_inode     - obtain an inode
 *    @sb: superblock
 *
 *    Allocates a new inode for given superblock. The default gfp_mask
 *    for allocations related to inode->i_mapping is GFP_HIGHUSER_MOVABLE.
 *    If HIGHMEM pages are unsuitable or it is known that pages allocated
 *    for the page cache are not reclaimable or migratable,
 *    mapping_set_gfp_mask() must be called with suitable flags on the
 *    newly created inode's mapping
 *
 */
struct inode *new_inode(struct super_block *sb)
{
    struct inode *inode;

    spin_lock_prefetch(&sb->s_inode_list_lock);

    inode = new_inode_pseudo(sb);
    if (inode)
        inode_sb_list_add(inode);
    return inode;
}
EXPORT_SYMBOL(new_inode);
```

new_inode_pseudo
----------------------------------------

https://github.com/novelinux/linux-4.x.y/blob/master/fs/inode.c/new_inode_pseudo.md
