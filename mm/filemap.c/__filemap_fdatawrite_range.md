# __filemap_fdatawrite_range

__filemap_fdatawrite_range函数会将<start, end>位置的dirty page回写。它首先构造一个struct writeback_control实例并初始化相应的字段，该结构体用于控制writeback回写操作，其中sync_mode表示同步模式，一共有WB_SYNC_NONE和WB_SYNC_ALL两种可选，前一种不会等待回写结束，一般用于周期性回写，后一种会等待回写结束，用于sync之类的强制回写；nr_to_write表示要回写的页数；range_start和range_end表示要会写的偏移起始和结束的位置，以字节为单位。

接下来调用mapping_cap_writeback_dirty函数判断文件所在的bdi是否支持回写动作，若不支持则直接返回0（表示写回的数量为0）；然后调用wbc_attach_fdatawrite_inode函数将wbc和inode的bdi进行绑定（需启用blk_cgroup内核属性，否则为空操作）；然后调用do_writepages执行回写动作，回写完毕后调用wbc_detach_inode函数将wbc和inode解除绑定。


```
/**
 * __filemap_fdatawrite_range - start writeback on mapping dirty pages in range
 * @mapping:	address space structure to write
 * @start:	offset in bytes where the range starts
 * @end:	offset in bytes where the range ends (inclusive)
 * @sync_mode:	enable synchronous operation
 *
 * Start writeback against all of a mapping's dirty pages that lie
 * within the byte offsets <start, end> inclusive.
 *
 * If sync_mode is WB_SYNC_ALL then this is a "data integrity" operation, as
 * opposed to a regular memory cleansing writeback.  The difference between
 * these two operations is that if a dirty page/buffer is encountered, it must
 * be waited upon, and not just skipped over.
 */
int __filemap_fdatawrite_range(struct address_space *mapping, loff_t start,
				loff_t end, int sync_mode)
{
	int ret;
	struct writeback_control wbc = {
		.sync_mode = sync_mode,
		.nr_to_write = LONG_MAX,
		.range_start = start,
		.range_end = end,
	};

	if (!mapping_cap_writeback_dirty(mapping))
		return 0;

	wbc_attach_fdatawrite_inode(&wbc, mapping->host);
```

## do_writepages

```
	ret = do_writepages(mapping, &wbc);
	wbc_detach_inode(&wbc);
	return ret;
}
```

https://github.com/novelinux/linux-4.x.y/blob/master/mm/page-writeback.c/do_writepages.md