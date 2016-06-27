ramfs_fill_super
========================================

path: fs/ramfs/inode.c
```
int ramfs_fill_super(struct super_block *sb, void *data, int silent)
{
    struct ramfs_fs_info *fsi;
    struct inode *inode;
    int err;

    save_mount_options(sb, data);

    fsi = kzalloc(sizeof(struct ramfs_fs_info), GFP_KERNEL);
    sb->s_fs_info = fsi;
    if (!fsi)
        return -ENOMEM;

    err = ramfs_parse_options(data, &fsi->mount_opts);
    if (err)
        return err;

    sb->s_maxbytes       = MAX_LFS_FILESIZE;
    sb->s_blocksize      = PAGE_CACHE_SIZE;
    sb->s_blocksize_bits = PAGE_CACHE_SHIFT;
    sb->s_magic          = RAMFS_MAGIC;
    sb->s_op             = &ramfs_ops;
    sb->s_time_gran      = 1;

    inode = ramfs_get_inode(sb, NULL, S_IFDIR | fsi->mount_opts.mode, 0);
    sb->s_root = d_make_root(inode);
    if (!sb->s_root)
        return -ENOMEM;

    return 0;
}
```

ramfs_get_inode
----------------------------------------

https://github.com/novelinux/linux-4.x.y/blob/master/fs/ramfs/inode.c/ramfs_get_inode.md
