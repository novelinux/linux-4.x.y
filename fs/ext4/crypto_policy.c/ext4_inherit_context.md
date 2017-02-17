# ext4_inherit_context


```
/**
 * ext4_inherit_context() - Sets a child context from its parent
 * @parent: Parent inode from which the context is inherited.
 * @child:  Child inode that inherits the context from @parent.
 *
 * Return: Zero on success, non-zero otherwise
 */
int ext4_inherit_context(struct inode *parent, struct inode *child)
{
	struct ext4_encryption_context ctx;
	struct ext4_crypt_info *ci;
	int res;

	res = ext4_get_encryption_info(parent);
	if (res < 0)
		return res;
	ci = EXT4_I(parent)->i_crypt_info;
	if (ci == NULL)
		return -ENOKEY;

	ctx.format = EXT4_ENCRYPTION_CONTEXT_FORMAT_V1;
	if (DUMMY_ENCRYPTION_ENABLED(EXT4_SB(parent->i_sb))) {
		ctx.contents_encryption_mode = EXT4_ENCRYPTION_MODE_AES_256_XTS;
		ctx.filenames_encryption_mode =
			EXT4_ENCRYPTION_MODE_AES_256_CTS;
		ctx.flags = 0;
		memset(ctx.master_key_descriptor, 0x42,
		       EXT4_KEY_DESCRIPTOR_SIZE);
		res = 0;
	} else {
		ctx.contents_encryption_mode = ci->ci_data_mode;
		ctx.filenames_encryption_mode = ci->ci_filename_mode;
		ctx.flags = ci->ci_flags;
		memcpy(ctx.master_key_descriptor, ci->ci_master_key,
		       EXT4_KEY_DESCRIPTOR_SIZE);
	}
	get_random_bytes(ctx.nonce, EXT4_KEY_DERIVATION_NONCE_SIZE);
	res = ext4_xattr_set(child, EXT4_XATTR_INDEX_ENCRYPTION,
			     EXT4_XATTR_NAME_ENCRYPTION_CONTEXT, &ctx,
			     sizeof(ctx), 0);
	if (!res) {
		ext4_set_inode_flag(child, EXT4_INODE_ENCRYPT);
		ext4_clear_inode_state(child, EXT4_STATE_MAY_INLINE_DATA);
		res = ext4_get_encryption_info(child);
	}
	return res;
}
```