inode_init_always
========================================

path: fs/inode.c
```
/**
 * inode_init_always - perform inode structure intialisation
 * @sb: superblock inode belongs to
 * @inode: inode to initialise
 *
 * These are initializations that need to be done on every inode
 * allocation as the fields are not initialised by slab allocation.
 */
int inode_init_always(struct super_block *sb, struct inode *inode)
{
    static const struct inode_operations empty_iops;
    static const struct file_operations no_open_fops = {.open = no_open};
    struct address_space *const mapping = &inode->i_data;

    inode->i_sb = sb;
    inode->i_blkbits = sb->s_blocksize_bits;
    inode->i_flags = 0;
    atomic_set(&inode->i_count, 1);
    inode->i_op = &empty_iops;
    inode->i_fop = &no_open_fops;
    inode->__i_nlink = 1;
    inode->i_opflags = 0;
    i_uid_write(inode, 0);
    i_gid_write(inode, 0);
    atomic_set(&inode->i_writecount, 0);
    inode->i_size = 0;
    inode->i_blocks = 0;
    inode->i_bytes = 0;
    inode->i_generation = 0;
    inode->i_pipe = NULL;
    inode->i_bdev = NULL;
    inode->i_cdev = NULL;
    inode->i_link = NULL;
    inode->i_rdev = 0;
    inode->dirtied_when = 0;

    if (security_inode_alloc(inode))
        goto out;
    spin_lock_init(&inode->i_lock);
    lockdep_set_class(&inode->i_lock, &sb->s_type->i_lock_key);

    mutex_init(&inode->i_mutex);
    lockdep_set_class(&inode->i_mutex, &sb->s_type->i_mutex_key);

    atomic_set(&inode->i_dio_count, 0);

    mapping->a_ops = &empty_aops;
    mapping->host = inode;
    mapping->flags = 0;
    atomic_set(&mapping->i_mmap_writable, 0);
    mapping_set_gfp_mask(mapping, GFP_HIGHUSER_MOVABLE);
    mapping->private_data = NULL;
    mapping->writeback_index = 0;
    inode->i_private = NULL;
    inode->i_mapping = mapping;
    INIT_HLIST_HEAD(&inode->i_dentry);    /* buggered by rcu freeing */
#ifdef CONFIG_FS_POSIX_ACL
    inode->i_acl = inode->i_default_acl = ACL_NOT_CACHED;
#endif

#ifdef CONFIG_FSNOTIFY
    inode->i_fsnotify_mask = 0;
#endif
    inode->i_flctx = NULL;
    this_cpu_inc(nr_inodes);

    return 0;
out:
    return -ENOMEM;
}
EXPORT_SYMBOL(inode_init_always);
```