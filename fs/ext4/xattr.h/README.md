xattrs
========================================

Extended attributes (xattrs) are typically stored in a separate data block
on the disk and referenced from inodes via inode.i_file_acl*. The first use
of extended attributes seems to have been for storing file ACLs and other
security data (selinux). With the user_xattr mount option it is possible
for users to store extended attributes so long as all attribute names
begin with "user"; this restriction seems to have disappeared as of Linux 3.0.

There are two places where extended attributes can be found:

1.The first place is between the end of each inode entry and the beginning of
the next inode entry. For example, if inode.i_extra_isize = 28 and
sb.inode_size = 256, then there are 256 - (128 + 28) = 100 bytes available
for in-inode extended attribute storage.

```
| Inode 1                                                 | Inode 2
|---------------------------------------------------------|------------------------------------|
| ext4_inode $ ext4_xattr_ibody_header + ext4_xattr_entry | ext4_inode $ ...                   |
|---------------------------------------------------------|------------------------------------|
```

2.The second place where extended attributes can be found is in the block
pointed to by inode.i_file_acl. As of Linux 3.11, it is not possible for
this block to contain a pointer to a second extended attribute block (or
even the remaining blocks of a cluster). In theory it is possible for each
attribute's value to be stored in a separate data block, though as of
Linux 3.11 the code does not permit this.

```
| Block 1 <- inode.i_file_acl_lo               | Block 2
|----------------------------------------------|--------------------------|
| ext4_xattr_header + ext4_xattr_entry $  ...  | ...                      |
|----------------------------------------------|--------------------------|
```

Keys are generally assumed to be ASCIIZ strings, whereas values can be strings or binary data.

Example - inode_set_capabilities
----------------------------------------

### inode_set_capabilities

path: system/extras/ext4_utils/contents.c
```
int inode_set_capabilities(u32 inode_num, uint64_t capabilities) {
	if (capabilities == 0)
		return 0;

	struct vfs_cap_data cap_data;
	memset(&cap_data, 0, sizeof(cap_data));

	cap_data.magic_etc = VFS_CAP_REVISION | VFS_CAP_FLAGS_EFFECTIVE;
	cap_data.data[0].permitted = (uint32_t) (capabilities & 0xffffffff);
	cap_data.data[0].inheritable = 0;
	cap_data.data[1].permitted = (uint32_t) (capabilities >> 32);
	cap_data.data[1].inheritable = 0;

	return xattr_add(inode_num, EXT4_XATTR_INDEX_SECURITY,
		XATTR_CAPS_SUFFIX, &cap_data, sizeof(cap_data));
}
```

### xattr_add

```
static int xattr_add(u32 inode_num, int name_index, const char *name,
		const void *value, size_t value_len)
{
	if (!value)
		return 0;

	struct ext4_inode *inode = get_inode(inode_num);

	if (!inode)
		return -1;

	int result = xattr_addto_inode(inode, name_index, name, value, value_len);
	if (result != 0) {
		result = xattr_addto_block(inode, name_index, name, value, value_len);
	}
	return result;
}
```

### xattr_addto_inode

```
static int xattr_addto_inode(struct ext4_inode *inode, int name_index,
		const char *name, const void *value, size_t value_len)
{
	struct ext4_xattr_ibody_header *hdr = (struct ext4_xattr_ibody_header *) (inode + 1);
	struct ext4_xattr_entry *first = (struct ext4_xattr_entry *) (hdr + 1);
	char *block_end = ((char *) inode) + info.inode_size;

	struct ext4_xattr_entry *result =
		xattr_addto_range(first, block_end, first, name_index, name, value, value_len);

	if (result == NULL)
		return -1;

	hdr->h_magic = cpu_to_le32(EXT4_XATTR_MAGIC);
	inode->i_extra_isize = cpu_to_le16(sizeof(struct ext4_inode) - EXT4_GOOD_OLD_INODE_SIZE);

	return 0;
}
```

### xattr_addto_block

```
static int xattr_addto_block(struct ext4_inode *inode, int name_index,
		const char *name, const void *value, size_t value_len)
{
	struct ext4_xattr_header *header = get_xattr_block_for_inode(inode);
	if (!header)
		return -1;

	struct ext4_xattr_entry *first = (struct ext4_xattr_entry *) (header + 1);
	char *block_end = ((char *) header) + info.block_size;

	struct ext4_xattr_entry *result =
		xattr_addto_range(header, block_end, first, name_index, name, value, value_len);

	if (result == NULL)
		return -1;

	ext4_xattr_hash_entry(header, result);
	return 0;
}
```

### xattr_addto_range

```
static struct ext4_xattr_entry* xattr_addto_range(
		void *block_start,
		void *block_end,
		struct ext4_xattr_entry *first,
		int name_index,
		const char *name,
		const void *value,
		size_t value_len)
{
	size_t name_len = strlen(name);
	if (name_len > 255)
		return NULL;

	size_t available_size = xattr_free_space(first, block_end);
	size_t needed_size = EXT4_XATTR_LEN(name_len) + EXT4_XATTR_SIZE(value_len);

	if (needed_size > available_size)
		return NULL;

	struct ext4_xattr_entry *new_entry = xattr_get_last(first);
	memset(new_entry, 0, EXT4_XATTR_LEN(name_len));

	new_entry->e_name_len = name_len;
	new_entry->e_name_index = name_index;
	memcpy(new_entry->e_name, name, name_len);
	new_entry->e_value_block = 0;
	new_entry->e_value_size = cpu_to_le32(value_len);

	char *val = (char *) new_entry + available_size - EXT4_XATTR_SIZE(value_len);
	size_t e_value_offs = val - (char *) block_start;

	new_entry->e_value_offs = cpu_to_le16(e_value_offs);
	memset(val, 0, EXT4_XATTR_SIZE(value_len));
	memcpy(val, value, value_len);

	xattr_assert_sane(first);
	return new_entry;
}
```