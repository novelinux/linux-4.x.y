ext4_is_encryption_context_consistent_with_policy
========================================

```
/*
 * check whether the policy is consistent with the encryption context
 * for the inode
 */
static int ext4_is_encryption_context_consistent_with_policy(
	struct inode *inode, const struct ext4_encryption_policy *policy)
{
	struct ext4_encryption_context ctx;
	int res = ext4_xattr_get(inode, EXT4_XATTR_INDEX_ENCRYPTION,
				 EXT4_XATTR_NAME_ENCRYPTION_CONTEXT, &ctx,
				 sizeof(ctx));
	if (res != sizeof(ctx))
		return 0;
	return (memcmp(ctx.master_key_descriptor, policy->master_key_descriptor,
			EXT4_KEY_DESCRIPTOR_SIZE) == 0 &&
		(ctx.flags ==
		 policy->flags) &&
		(ctx.contents_encryption_mode ==
		 policy->contents_encryption_mode) &&
		(ctx.filenames_encryption_mode ==
		 policy->filenames_encryption_mode));
}
```