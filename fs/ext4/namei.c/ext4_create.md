ext4_create
========================================

Arguments
----------------------------------------

path: fs/ext4/namei.c
```
/*
 * By the time this is called, we already have created
 * the directory cache entry for the new file, but it
 * is so far negative - it has no inode.
 *
 * If the create succeeds, we fill in the inode information
 * with d_instantiate().
 */
static int ext4_create(struct inode *dir, struct dentry *dentry, umode_t mode,
               bool excl)
{
    handle_t *handle;
    struct inode *inode;
    int err, credits, retries = 0;

    err = dquot_initialize(dir);
    if (err)
        return err;

    credits = (EXT4_DATA_TRANS_BLOCKS(dir->i_sb) +
           EXT4_INDEX_EXTRA_TRANS_BLOCKS + 3);
```

ext4_new_inode_start_handle
----------------------------------------

```
retry:
    inode = ext4_new_inode_start_handle(dir, mode, &dentry->d_name, 0,
                        NULL, EXT4_HT_DIR, credits);
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/ext4/ext4.h/ext4_new_inode_start_handle.md

ext4_journal_current_handle
----------------------------------------

```
    handle = ext4_journal_current_handle();
```

i_op, i_fop, i_aops
----------------------------------------

```
    err = PTR_ERR(inode);
    if (!IS_ERR(inode)) {
        inode->i_op = &ext4_file_inode_operations;
        inode->i_fop = &ext4_file_operations;
        ext4_set_aops(inode);
        err = ext4_add_nondir(handle, dentry, inode);
        if (!err && IS_DIRSYNC(dir))
            ext4_handle_sync(handle);
    }
```

### ext4_file_inode_operations

https://github.com/novelinux/linux-4.x.y/tree/master/fs/ext4/file.c/ext4_file_inode_operations.md

### ext4_file_operations

https://github.com/novelinux/linux-4.x.y/tree/master/fs/ext4/file.c/ext4_file_operations.md

### ext4_set_aops

https://github.com/novelinux/linux-4.x.y/tree/master/fs/ext4/inode.c/ext4_set_aops.md

ext4_journal_stop
----------------------------------------

```
    if (handle)
        ext4_journal_stop(handle);
    if (err == -ENOSPC && ext4_should_retry_alloc(dir->i_sb, &retries))
        goto retry;
    return err;
}
```
