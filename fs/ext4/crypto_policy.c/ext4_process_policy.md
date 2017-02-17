ext4_process_policy
========================================

path: fs/ext4/crypto_policy.c
```
int ext4_process_policy(const struct ext4_encryption_policy *policy,
			struct inode *inode)
{
	if (policy->version != 0)
		return -EINVAL;
```

ext4_inode_has_encryption_context
----------------------------------------

```
	if (!ext4_inode_has_encryption_context(inode)) {
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/ext4/crypto_policy.c/ext4_inode_has_encryption_context.md

ext4_create_encryption_context_from_policy
-----------------------------------------

```
		if (!S_ISDIR(inode->i_mode))
			return -EINVAL;
		if (!ext4_empty_dir(inode))
			return -ENOTEMPTY;
		return ext4_create_encryption_context_from_policy(inode,
								  policy);
	}
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/ext4/crypto_policy.c/ext4_create_encryption_context_from_policy.md

ext4_is_encryption_context_consistent_with_policy
----------------------------------------

```
	if (ext4_is_encryption_context_consistent_with_policy(inode, policy))
		return 0;

	printk(KERN_WARNING "%s: Policy inconsistent with encryption context\n",
	       __func__);
	return -EINVAL;
}
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/ext4/crypto_policy.c/ext4_is_encryption_context_consistent_with_policy.md
