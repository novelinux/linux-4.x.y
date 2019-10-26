## new_sync_read

Linux中最常用的输入/输出(I/O)模型是同步 I/O。在这个模型中,当请求发出之后,应用
程序就会阻塞,直到请求满足为止。同步I/O场景下,调用应用程序在等待 I/O 请求完成时不
需要使用任何CPU执行。但是在某些情况中,I/O 请求可能需要与其他进程产生交叠。可移植
操作系统接口(POSIX)异步 I/O应用程序接口就提供了这种功能。

异步I/O背后的基本思想是允许进程发起很多 I/O 操作,而不用阻塞或等待任何操作完
成。稍后或在接收到 I/O 操作完成的通知时,进程就可以检索 I/O 操作的结果。异步 I/O 允
许用户空间来初始化操作而不必等待它们的完成; 因此, 一个应用程序可以在它的 I/O 在进
行中时做其他的处理。一个复杂的、高性能的应用程序还可使用异步 I/O 来使多个操作在同一
个时间进行。

```
static ssize_t new_sync_read(struct file *filp, char __user *buf, size_t len, loff_t *ppos)
{
	struct iovec iov = { .iov_base = buf, .iov_len = len };
	struct kiocb kiocb;
	struct iov_iter iter;
	ssize_t ret;

	init_sync_kiocb(&kiocb, filp);
	kiocb.ki_pos = *ppos;
	iov_iter_init(&iter, READ, &iov, 1, len);

	ret = filp->f_op->read_iter(&kiocb, &iter);
	BUG_ON(ret == -EIOCBQUEUED);
	*ppos = kiocb.ki_pos;
	return ret;
}
```

[read_iter](../ext4/file.c/ext4_file_operations.md)