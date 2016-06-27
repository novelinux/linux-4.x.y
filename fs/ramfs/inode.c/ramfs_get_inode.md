ramfs_get_inode
========================================

path: fs/ramfs/inode.c
```
struct inode *ramfs_get_inode(struct super_block *sb,
                const struct inode *dir, umode_t mode, dev_t dev)
{
    struct inode * inode = new_inode(sb);

    if (inode) {
        inode->i_ino = get_next_ino();
        inode_init_owner(inode, dir, mode);
        inode->i_mapping->a_ops = &ramfs_aops;
        mapping_set_gfp_mask(inode->i_mapping, GFP_HIGHUSER);
        mapping_set_unevictable(inode->i_mapping);
        inode->i_atime = inode->i_mtime = inode->i_ctime = CURRENT_TIME;
        switch (mode & S_IFMT) {
        default:
            init_special_inode(inode, mode, dev);
            break;
        case S_IFREG:
            inode->i_op = &ramfs_file_inode_operations;
            inode->i_fop = &ramfs_file_operations;
            break;
        case S_IFDIR:
            inode->i_op = &ramfs_dir_inode_operations;
            inode->i_fop = &simple_dir_operations;

            /* directory inodes start off with i_nlink == 2 (for "." entry) */
            inc_nlink(inode);
            break;
        case S_IFLNK:
            inode->i_op = &page_symlink_inode_operations;
            break;
        }
    }
    return inode;
}
```