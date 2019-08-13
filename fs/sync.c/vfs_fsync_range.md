# vfs_fsync_range

vfs_fsync_range函数首先从file结构体的addess_space中找到文件所属的inode（地址映射address_space结构在open文件时的sys_open->do_dentry_open调用中初始化，
里面保存了该文件的所有建立的page cache、底层块设备和对应的操作函数集），然后判断文件系统的file_operation函数集是否实现了fsync接口，如果未实现直接返回EINVAL。


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

### mark_inode_dirty_sync

接下来在非datasync（sync）的情况下会对inode的I_DIRTY_TIME标记进行判断，如果置位了该标识（表示该文件的时间戳已经发生了跟新但还没有同步到磁盘上）则清除该标志位并调用mark_inode_dirty_sync设置I_DIRTY_SYNC标识，表示需要进行sync同步操作。该函数会针对当前inode所在的不同state进行区别处理，同时会将inode添加到后台回刷bdi的Dirty list上去（bdi回写任务会遍历该list执行同步操作，当然容易导致误解的是当前的回写流程是不会由bdi write back worker来执行的，而是在本调用流程中就直接一气呵成的）。

https://github.com/novelinux/linux-4.x.y/blob/master/fs/ext4/inode.c/ext4_inode_dirty.md

### fsync

https://github.com/novelinux/linux-4.x.y/blob/master/fs/ext4/file.c/ext4_file_operations.md
