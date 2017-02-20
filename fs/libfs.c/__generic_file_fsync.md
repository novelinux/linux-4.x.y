# __generic_file_fsync

```
/**
 * __generic_file_fsync - generic fsync implementation for simple filesystems
 *
 * @file:	file to synchronize
 * @start:	start offset in bytes
 * @end:	end offset in bytes (inclusive)
 * @datasync:	only synchronize essential metadata if true
 *
 * This is a generic implementation of the fsync method for simple
 * filesystems which track all non-inode metadata in the buffers list
 * hanging off the address_space structure.
 */
int __generic_file_fsync(struct file *file, loff_t start, loff_t end,
				 int datasync)
{
	struct inode *inode = file->f_mapping->host;
	int err;
	int ret;
```

## filemap_write_and_wait_range

```
	err = filemap_write_and_wait_range(inode->i_mapping, start, end);
	if (err)
		return err;
```

https://github.com/novelinux/linux-4.x.y/blob/master/mm/filemap.c/filemap_write_and_wait_range.md

## sync_mapping_buffers

```
	mutex_lock(&inode->i_mutex);
	ret = sync_mapping_buffers(inode->i_mapping);
	if (!(inode->i_state & I_DIRTY_ALL))
		goto out;
	if (datasync && !(inode->i_state & I_DIRTY_DATASYNC))
		goto out;

	err = sync_inode_metadata(inode, 1);
	if (ret == 0)
		ret = err;

out:
	mutex_unlock(&inode->i_mutex);
	return ret;
}
EXPORT_SYMBOL(__generic_file_fsync);
```