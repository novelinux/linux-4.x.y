# vfs_fsync_range

```
/**
 * vfs_fsync_range - helper to sync a range of data & metadata to disk
 * @file:		file to sync
 * @start:		offset in bytes of the beginning of data range to sync
 * @end:		offset in bytes of the end of data range (inclusive)
 * @datasync:		perform only datasync
 *
 * Write back data in range @start..@end and metadata for @file to disk.  If
 * @datasync is set only metadata needed to access modified file data is
 * written.
 */
int vfs_fsync_range(struct file *file, loff_t start, loff_t end, int datasync)
{
	struct inode *inode = file->f_mapping->host;

	if (!file->f_op->fsync)
		return -EINVAL;
	if (!datasync && (inode->i_state & I_DIRTY_TIME)) {
		spin_lock(&inode->i_lock);
		inode->i_state &= ~I_DIRTY_TIME;
		spin_unlock(&inode->i_lock);
		mark_inode_dirty_sync(inode);
	}
	return file->f_op->fsync(file, start, end, datasync);
}
EXPORT_SYMBOL(vfs_fsync_range);
```

## EXT4

### fsync

https://github.com/novelinux/linux-4.x.y/blob/master/fs/ext4/file.c/ext4_file_operations.md
