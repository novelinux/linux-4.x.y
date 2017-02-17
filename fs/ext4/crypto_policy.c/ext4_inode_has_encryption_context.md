ext4_inode_has_encryption_context
========================================

```
static int ext4_inode_has_encryption_context(struct inode *inode)
{
	int res = ext4_xattr_get(inode, EXT4_XATTR_INDEX_ENCRYPTION,
				 EXT4_XATTR_NAME_ENCRYPTION_CONTEXT, NULL, 0);
	return (res > 0);
}
```
