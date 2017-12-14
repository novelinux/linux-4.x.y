# lookup_slow

不是在内存中没找到才进来的吗，怎么这里又调用d_alloc_parallel去内存中找一遍？别忘了，
上一级函数使用了rw_semaphore，这将有可能导致进程睡眠，也就有可能恰好有人在我们睡觉的时候
这个目标加载进了内存，所以这里需要检查一下，而且反正是在内存中查找，不会太费事的。要是真找到了呢，
那就撞大运了，高高兴兴的返回吧，要还是没有就只好自己动手丰衣足食老老实实的启动 lookup_real ，
从真正的文件系统上读取吧。lookup_real 我们就不深入进去了，在里面主要是调用了具体文件系统自己的
lookup 函数去完成工作，而这些函数很有可能会启动文件系统所在设备的驱动程序，
从真正的设备上读取（例如硬盘）数据，所以就更慢了，这才是名副其实的“lookup_slow”。

```
/* Fast lookup failed, do it the slow way */
static struct dentry *lookup_slow(const struct qstr *name,
				  struct dentry *dir,
				  unsigned int flags)
{
	struct dentry *dentry = ERR_PTR(-ENOENT), *old;
	struct inode *inode = dir->d_inode;
	DECLARE_WAIT_QUEUE_HEAD_ONSTACK(wq);

	inode_lock_shared(inode);
	/* Don't go there if it's already dead */
	if (unlikely(IS_DEADDIR(inode)))
		goto out;
```

## d_alloc_parallel

```
again:
	dentry = d_alloc_parallel(dir, name, &wq);
	if (IS_ERR(dentry))
		goto out;
	if (unlikely(!d_in_lookup(dentry))) {
		if (!(flags & LOOKUP_NO_REVAL)) {
			int error = d_revalidate(dentry, flags);
			if (unlikely(error <= 0)) {
				if (!error) {
					d_invalidate(dentry);
					dput(dentry);
					goto again;
				}
				dput(dentry);
				dentry = ERR_PTR(error);
			}
		}
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/dcache.c/d_alloc_parallel.md

## inode->i_op->lookup

```
	} else {
		old = inode->i_op->lookup(inode, dentry, flags);
		d_lookup_done(dentry);
		if (unlikely(old)) {
			dput(dentry);
			dentry = old;
		}
	}
out:
	inode_unlock_shared(inode);
	return dentry;
}
```
