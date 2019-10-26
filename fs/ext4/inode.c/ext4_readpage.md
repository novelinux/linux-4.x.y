# ext4_readpage

前面提到Linux内核读文件通常采取预读机制,不是每次只读一个页面。在do_generic_file_read()函数中,执行最多的是page_cache_sync_readahead()和page_cache_async_readahead(),很少直接调用mapping->a_ops->readpage()。在预读机制中,会调用mapping->a_ops->readpages()一次读取多个页面。
这里我们先分析执行较少时的情形,调用a_ops->readpage ()一次读取一个页面。

```
static int ext4_readpage(struct file *file, struct page *page)
{
	int ret = -EAGAIN;
	struct inode *inode = page->mapping->host;

	trace_ext4_readpage(page);

	if (ext4_has_inline_data(inode))
		ret = ext4_readpage_inline(inode, page);

	if (ret == -EAGAIN)
		return ext4_mpage_readpages(page->mapping, NULL, page, 1);

	return ret;
}
```

[ext4_mpage_readpages](../readpage.c/ext4_mpage_readpages.md)