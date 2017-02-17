# ext4_encrypted_inode

```
/*
 * Returns true if the inode is inode is encrypted
 */
static inline int ext4_encrypted_inode(struct inode *inode)
{
#ifdef CONFIG_EXT4_FS_ENCRYPTION
	return ext4_test_inode_flag(inode, EXT4_INODE_ENCRYPT);
#else
	return 0;
#endif
}
```
