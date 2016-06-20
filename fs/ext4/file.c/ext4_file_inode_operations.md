ext4_file_inode_operations
========================================

setattr
----------------------------------------

path: fs/ext4/file.c
```
const struct inode_operations ext4_file_inode_operations = {
    .setattr    = ext4_setattr,
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/ext4/inode.c/ext4_setattr.md

getattr
----------------------------------------

```
    .getattr    = ext4_getattr,
    .setxattr    = generic_setxattr,
    .getxattr    = generic_getxattr,
    .listxattr    = ext4_listxattr,
    .removexattr    = generic_removexattr,
    .get_acl    = ext4_get_acl,
    .set_acl    = ext4_set_acl,
    .fiemap        = ext4_fiemap,
};
```