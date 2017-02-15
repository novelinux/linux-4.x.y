struct ext4_xattr_header
========================================

path: fs/ext4/xattr.h
```
struct ext4_xattr_header {
	__le32	h_magic;	/* magic number for identification */
	__le32	h_refcount;	/* reference count */
	__le32	h_blocks;	/* number of disk blocks used */
	__le32	h_hash;		/* hash value of all attributes */
	__le32	h_checksum;	/* crc32c(uuid+id+xattrblock) */
				/* id = inum if refcount=1, blknum otherwise */
	__u32	h_reserved[3];	/* zero right now */
};
```
