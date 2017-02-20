# do_writepages

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
