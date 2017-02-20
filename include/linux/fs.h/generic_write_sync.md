# generic_write_sync

```
static inline int generic_write_sync(struct file *file, loff_t pos, loff_t count)
{
	if (!(file->f_flags & O_DSYNC) && !IS_SYNC(file->f_mapping->host))
		return 0;
	return vfs_fsync_range(file, pos, pos + count - 1,
			       (file->f_flags & __O_SYNC) ? 0 : 1);
}
```

## vfs_fsync_range

https://github.com/novelinux/linux-4.x.y/blob/master/fs/sync.c/vfs_fsync_range.md
