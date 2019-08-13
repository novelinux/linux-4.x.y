# ext4_sync_file

首先明确几个局部变量：1、commit_tid是日志提交事物的transaction id，用来区分不同的事物（transaction）；2、needs_barrier用于表示是否需要对所在的块设备发送cache刷写命令，是一种用于保护数据一致性的手段。这几个局部变量后面会看到是如何使用的，这里先关注一下。
ext4_sync_file函数首先判断文件系统只读的情况，对于一般以只读方式挂载的文件系统由于不会写入文件，所以不需要执行fsync/fdatasync操作，立即返回success即可。但是文件系统只读也可能是发生了错误导致的，因此这里会做一个判断，如果文件系统abort（出现致命错误），就需要返回EROFS而不是success，这样做是为了避免应用程序误认为文件已经同步成功了。

```
/*
 * akpm: A new design for ext4_sync_file().
 *
 * This is only called from sys_fsync(), sys_fdatasync() and sys_msync().
 * There cannot be a transaction open by this task.
 * Another task could have dirtied this inode.  Its data can be in any
 * state in the journalling system.
 *
 * What we do is just kick off a commit and wait on it.  This will snapshot the
 * inode to disk.
 */

int ext4_sync_file(struct file *file, loff_t start, loff_t end, int datasync)
{
	struct inode *inode = file->f_mapping->host;
	struct ext4_inode_info *ei = EXT4_I(inode);
	journal_t *journal = EXT4_SB(inode->i_sb)->s_journal;
	int ret = 0, err;
	tid_t commit_tid;
	bool needs_barrier = false;

	J_ASSERT(ext4_journal_current_handle() == NULL);

	trace_ext4_sync_file_enter(file, datasync);

	if (inode->i_sb->s_flags & MS_RDONLY) {
		/* Make sure that we read updated s_mount_flags value */
		smp_rmb();
		if (EXT4_SB(inode->i_sb)->s_mount_flags & EXT4_MF_FS_ABORTED)
			ret = -EROFS;
		goto out;
	}
```

## generic_file_fsync

接下来处理未开启日志的情况，这种情况下将调用通用函数__generic_file_fsync进行文件同步，随后调用ext4_sync_parent对文件所在的父目录进行同步。之所以要同步父目录是因为在未开启日志的情况下，若同步的是一个新创建的文件，那么待到父目录的目录项通过writeback后台回写之间将有一个巨大的时间窗口，在这段时间内掉电或者系统崩溃就会导致数据的丢失，所以这里及时同步父目录项将该时间窗大大的缩短，也就提高了数据的安全性。ext4_sync_parent函数会对它的父目录进行递归，若是新创建的目录都将进行同步。

```
	if (!journal) {
		ret = generic_file_fsync(file, start, end, datasync);
		if (!ret && !hlist_empty(&inode->i_dentry))
			ret = ext4_sync_parent(inode);
		goto out;
	}
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/libfs.c/generic_file_fsync.md

## filemap_write_and_wait_range


由于在默认情况下是启用日志的（jbd2日志模块journal在mount文件系统时的ext4_fill_super->ext4_load_journal调用流程中初始化），所以这个分支暂不详细分析，回到ext4_sync_file中分析默认开启日志的情况。接下来调用filemap_write_and_wait_range回写从start到end的dirty文件数据块并等待回写完成。


```
	ret = filemap_write_and_wait_range(inode->i_mapping, start, end);
	if (ret)
		return ret;
```

https://github.com/novelinux/linux-4.x.y/blob/master/mm/filemap.c/filemap_write_and_wait_range.md

文件的数据回写就完成了，而元数据尚在日志事物中等待提交，接下来回到最外层的ext4_sync_file函数，提交最后的元数据块。

## out

参考注释中的说明，对于默认的ordered模式，前面的filemap_write_and_wait_range函数已经同步了文件的数据块，而元数据块可能仍然在日志journal里，接下来的流程会找到一个合适的事物来进行日志的提交。
首先做一个判断，如果启用了文件系统的barrier特性，这里会调用jbd2_trans_will_send_data_barrier函数判断是否需要向块设备发送flush指令，需要注意的是commit_tid参数，如果是fdatasync调用，那它使用ei->i_datasync_tid，否则使用ei->i_sync_tid，用以表示包含我们关注文件元数据所在当前的事物id。

jbd2_trans_will_send_data_barrier函数会对当前日志的状态进行一系列判断，返回1表示当前的transaction还没有被提交，所以不发送flush指令，返回0表示当前的事物可能已经被提交了，因此需要发送flush。具体如下：
（1）文件系统日志模式不支持barrier，这里返回0会触发flush
（2）当前的事物id号和journal->j_commit_sequence进行比较，如果j_commit_sequence大于该id号表示这里关注的事物已经被提交了，返回0；
（3）如果正在提交的事物不存在或者正在提交的事物不是所当前的事物，表示当前的事物被日志提交进程所处理，返回1；
（4）如果当前的事物正在提交中且提交已经进行到T_COMMIT_JFLUSH，表明元数据日志已经写回完毕了，返回0；
（5）最后如果当前的事物正在提交中但是还没有将元数据日志写回，返回1。

```
	/*
	 * data=writeback,ordered:
	 *  The caller's filemap_fdatawrite()/wait will sync the data.
	 *  Metadata is in the journal, we wait for proper transaction to
	 *  commit here.
	 *
	 * data=journal:
	 *  filemap_fdatawrite won't do anything (the buffers are clean).
	 *  ext4_force_commit will write the file data into the journal and
	 *  will wait on that.
	 *  filemap_fdatawait() will encounter a ton of newly-dirtied pages
	 *  (they were dirtied by commit).  But that's OK - the blocks are
	 *  safe in-journal, which is all fsync() needs to ensure.
	 */
	if (ext4_should_journal_data(inode)) {
		ret = ext4_force_commit(inode->i_sb);
		goto out;
	}

	commit_tid = datasync ? ei->i_datasync_tid : ei->i_sync_tid;
	if (journal->j_flags & JBD2_BARRIER &&
	    !jbd2_trans_will_send_data_barrier(journal, commit_tid))
		needs_barrier = true;
```

首先如果当前正在运行的日志事物（尚有日志原子操作handle正在进行或者日志提交进程还没触发提交动作）且正是当前的事物，那么立即调用jbd2_log_start_commit函数唤醒日志回写进程回写待提交的元数据，然后调用jbd2_log_wait_commit函数等待元数据日志回写完毕（注意：并不保证元数据自身回写完毕，但是由于日志回写完毕后即使此刻系统崩溃，文件的元数据也能够得到恢复，因此文中其他地方不再对此详细区分），这也是正常情况下一般的流程；但是如果当前的事物已经在回写中了，那只需要等待即可；最后如果是没有正在提交的事物或提交的事物不为等待的事物id，表示事物已经写回了，所以直接退出即可。


```
	ret = jbd2_complete_transaction(journal, commit_tid);
```

最后根据前面的判断结果，如果需要下发flush指令，则调用blkdev_issue_flush函数向块设备下发flush命令，该命令最终会向物理磁盘发送一条flush cache的SCSI指令，磁盘会回刷磁盘写cache，这样数据才会真正的落盘，真正的安全了。为什么是否需要下发flush的判断会放在jbd2_complete_transaction之前，在jbd2_complete_transaction之后判断岂不是更好？因为jbd2_complete_transaction之后是能够保证当前的事物提交完毕，所以只需要判断journal是否支持barrier就可以了。现在这样处理岂不是会漏掉前文中的3和5两种情况不下发flush指令？


```
	if (needs_barrier) {
		err = blkdev_issue_flush(inode->i_sb->s_bdev, GFP_KERNEL, NULL);
		if (!ret)
			ret = err;
	}
out:
	trace_ext4_sync_file_exit(inode, ret);
	return ret;
}
```

我们检查EXT4文件系统如何控制fsync（）中的存储顺序。在有序日记模式下（默认），数据块在日记事务之前持久化。文件系统为一组脏页面发出写请求，D可能由来自不同文件的数据块组成。发出写入请求后，应用程序线程会等待DMA传输完成。当DMA传输完成时，应用程序线程恢复并触发JBD线程提交日志事务。触发JBD线程后，应用程序线程再次休眠。当JBD线程使日志事务持久化时，fsync（）返回。应该强调的是应用程序线程只有在D传输后才会触发JBD线程。否则，存储控制器可能以无序方式服务于写入请求D和用于日志提交的写入请求，并且存储控制器可能过早地持久化日志事务（在D被传送之前）

  日志事务通常使用两个写入请求来提交：一个用于写入日志描述符块和日志块的合并块，另一个用于写入提交块。在本文的其余部分，我们将分别使用JD和JC来表示日志描述符和日志块的合并块，以及提交块。在提交日志事务时，JBD需要在两个关系中执行存储顺序：事务内和事务间。在事务内，JBD需要确保JD在JC之前持久。在事务间，JBD必须确保日记事务按序持久化。当违反这两个条件中的任何一个时，如果发生意外故障，文件系统可能会错误地恢复[67,9]。对于事务内的存储顺序，JBD将JD的写入请求和JC的写入请求与Transfer-and-Flush交错。为了控制事务之间的存储顺序，JBD线程在开始提交后面的事务之前等待JC变为持久。 JBD使用Transfer-and-Flush机制来执行intra-transaction（内部事务）和inter-transaction（事务间）存储顺序。

  在早期的Linux中，块设备层在提交日志事务时显式发出flush命令[15]。在这种方法中，flush命令不仅阻塞调用者，而且阻塞同一个调度队列中的其他请求。从Linux 2.6.37开始，文件系统（JBD）隐式地发出了一个flush命令[16]。在写入JC时，JBD用REQ_FLUSH和REQ_FUA标记写入请求。大多数存储控制器已经演变为支持这两个标志;有了这两个标志，存储控制器在为命令提供服务之前刷新写回缓存，并在服务命令时，它直接持久化JC到存储表面，绕过写回缓存。在这种方法中，只有JBD线程块和共享相同调度队列的其他线程才能继续。我们的努力可以被认为是IO堆栈演化的延续。我们通过使存储设备更具能力来缓解Transfer-and-Flush开销：支持屏障命令并相应地重新设计主机端IO堆栈。