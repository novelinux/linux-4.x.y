# do_writepages

do_writepages函数将优先调用地址空间a_ops函数集中的writepages注册函数，ext4文件系统实现为ext4_writepages，若没有实现则调用通用函数generic_writepages（该函数在后台赃页回刷进程wb_workfn函数调用流程中也会被调用来执行回写操作）。

```
int do_writepages(struct address_space *mapping, struct writeback_control *wbc)
{
	int ret;

	if (wbc->nr_to_write <= 0)
		return 0;
	if (mapping->a_ops->writepages)
		ret = mapping->a_ops->writepages(mapping, wbc);
	else
		ret = generic_writepages(mapping, wbc);
	return ret;
}
```

## EXT4

### ext4_set_aops

https://github.com/novelinux/linux-4.x.y/tree/master/fs/ext4/inode.c/ext4_set_aops.md

### writepages

https://github.com/novelinux/linux-4.x.y/tree/master/fs/ext4/inode.c/ext4_aops.md
