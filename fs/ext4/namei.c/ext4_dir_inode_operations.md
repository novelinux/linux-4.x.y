ext4_dir_inode_operations
========================================

create
----------------------------------------

path: fs/ext4/namei.c
```
/*
 * directories can handle most operations...
 */
const struct inode_operations ext4_dir_inode_operations = {
    .create        = ext4_create,
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/ext4/namei.c/ext4_create.md

lookup
----------------------------------------

```
    .lookup        = ext4_lookup,
    .link        = ext4_link,
    .unlink        = ext4_unlink,
    .symlink    = ext4_symlink,
    .mkdir        = ext4_mkdir,
    .rmdir        = ext4_rmdir,
    .mknod        = ext4_mknod,
    .tmpfile    = ext4_tmpfile,
    .rename2    = ext4_rename2,
    .setattr    = ext4_setattr,
    .setxattr    = generic_setxattr,
    .getxattr    = generic_getxattr,
    .listxattr    = ext4_listxattr,
    .removexattr    = generic_removexattr,
    .get_acl    = ext4_get_acl,
    .set_acl    = ext4_set_acl,
    .fiemap         = ext4_fiemap,
};
```