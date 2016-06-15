ext4_file_inode_operations
========================================

path: fs/ext4/file.c
```
const struct inode_operations ext4_file_inode_operations = {
    .setattr    = ext4_setattr,
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