alloc_inode
========================================

Arguments
----------------------------------------

path: fs/inode.c
```
static struct inode *alloc_inode(struct super_block *sb)
{
    struct inode *inode;

    if (sb->s_op->alloc_inode)
        inode = sb->s_op->alloc_inode(sb);
    else
        inode = kmem_cache_alloc(inode_cachep, GFP_KERNEL);

    if (!inode)
        return NULL;
```

inode_init_always
----------------------------------------

```
    if (unlikely(inode_init_always(sb, inode))) {
        if (inode->i_sb->s_op->destroy_inode)
            inode->i_sb->s_op->destroy_inode(inode);
        else
            kmem_cache_free(inode_cachep, inode);
        return NULL;
    }

    return inode;
}
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/inode.c/inode_init_always.md
