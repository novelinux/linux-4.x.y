ext4_create_encryption_context_from_policy
========================================

```
static int ext4_create_encryption_context_from_policy(
	struct inode *inode, const struct ext4_encryption_policy *policy)
{
	struct ext4_encryption_context ctx;
	handle_t *handle;
	int res, res2;

	res = ext4_convert_inline_data(inode);
	if (res)
		return res;

	ctx.format = EXT4_ENCRYPTION_CONTEXT_FORMAT_V1;
	memcpy(ctx.master_key_descriptor, policy->master_key_descriptor,
	       EXT4_KEY_DESCRIPTOR_SIZE);
	if (!ext4_valid_contents_enc_mode(policy->contents_encryption_mode)) {
		printk(KERN_WARNING
		       "%s: Invalid contents encryption mode %d\n", __func__,
			policy->contents_encryption_mode);
		return -EINVAL;
	}
	if (!ext4_valid_filenames_enc_mode(policy->filenames_encryption_mode)) {
		printk(KERN_WARNING
		       "%s: Invalid filenames encryption mode %d\n", __func__,
			policy->filenames_encryption_mode);
		return -EINVAL;
	}
	if (policy->flags & ~EXT4_POLICY_FLAGS_VALID)
		return -EINVAL;
	ctx.contents_encryption_mode = policy->contents_encryption_mode;
	ctx.filenames_encryption_mode = policy->filenames_encryption_mode;
	ctx.flags = policy->flags;
	BUILD_BUG_ON(sizeof(ctx.nonce) != EXT4_KEY_DERIVATION_NONCE_SIZE);
	get_random_bytes(ctx.nonce, EXT4_KEY_DERIVATION_NONCE_SIZE);

	handle = ext4_journal_start(inode, EXT4_HT_MISC,
				    ext4_jbd2_credits_xattr(inode));
	if (IS_ERR(handle))
		return PTR_ERR(handle);
	res = ext4_xattr_set(inode, EXT4_XATTR_INDEX_ENCRYPTION,
			     EXT4_XATTR_NAME_ENCRYPTION_CONTEXT, &ctx,
			     sizeof(ctx), 0);
	if (!res) {
		ext4_set_inode_flag(inode, EXT4_INODE_ENCRYPT);
		res = ext4_mark_inode_dirty(handle, inode);
		if (res)
			EXT4_ERROR_INODE(inode, "Failed to mark inode dirty");
	}
	res2 = ext4_journal_stop(handle);
	if (!res)
		res = res2;
	return res;
}
```
