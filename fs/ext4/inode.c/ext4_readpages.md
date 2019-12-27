## ext4_readpages

```
static int
ext4_readpages(struct file *file, struct address_space *mapping,
		struct list_head *pages, unsigned nr_pages)
{
	struct inode *inode = mapping->host;

	/* If the file has inline data, no need to do readpages. */
	if (ext4_has_inline_data(inode))
		return 0;

	return ext4_mpage_readpages(mapping, pages, NULL, nr_pages, true);
}
```

[ext4_mpage_readpages](../readpage.c/ext4_mpage_readpages.md)