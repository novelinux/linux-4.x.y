# filemap_fdatawrite

```
int filemap_fdatawrite(struct address_space *mapping)
{
	return __filemap_fdatawrite(mapping, WB_SYNC_ALL);
}
EXPORT_SYMBOL(filemap_fdatawrite);
```

## __filemap_fdatawrite

https://github.com/novelinux/linux-4.x.y/blob/master/mm/filemap.c/__filemap_fdatawrite.md