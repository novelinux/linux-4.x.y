# ext4_dirty_inode

ext4_dirty_inode函数涉及ext4文件系统使用的jbd2日志模块，它将启用一个新的日志handle（日志原子操作）并将应该同步的inode元数据block向日志jbd2模块transaction进行提交（注意不会立即写日志和回写）。其中ext4_journal_start函数会简单判断一下ext4文件系统的日志执行状态最后直接调用jbd2__journal_start来启用日志handle；然后ext4_mark_inode_dirty函数会调用ext4_get_inode_loc获取inode元数据所在的buffer head映射block，按照标准的日志提交流程jbd2_journal_get_write_access（获取写权限）-> 对元数据raw_inode进行更新 -> jbd2_journal_dirty_metadata（设置元数据为脏并添加到日志transaction的对应链表中）；最后ext4_journal_stop->jbd2_journal_stop调用流程结束这个handle原子操作。这样后面日志commit进程会对日志的元数据块进行提交（注意，这里并不会立即唤醒日志commit进程启动日志提交动作，启用largefile特性除外）。

```
/*
 * ext4_dirty_inode() is called from __mark_inode_dirty()
 *
 * We're really interested in the case where a file is being extended.
 * i_size has been changed by generic_commit_write() and we thus need
 * to include the updated inode in the current transaction.
 *
 * Also, dquot_alloc_block() will always dirty the inode when blocks
 * are allocated to the file.
 *
 * If the inode is marked synchronous, we don't honour that here - doing
 * so would cause a commit on atime updates, which we don't bother doing.
 * We handle synchronous inodes at the highest possible level.
 *
 * If only the I_DIRTY_TIME flag is set, we can skip everything.  If
 * I_DIRTY_TIME and I_DIRTY_SYNC is set, the only inode fields we need
 * to copy into the on-disk inode structure are the timestamp files.
 */
void ext4_dirty_inode(struct inode *inode, int flags)
{
	handle_t *handle;

	if (flags == I_DIRTY_TIME)
		return;
	handle = ext4_journal_start(inode, EXT4_HT_INODE, 2);
	if (IS_ERR(handle))
		goto out;

	ext4_mark_inode_dirty(handle, inode);

	ext4_journal_stop(handle);
out:
	return;
}
```