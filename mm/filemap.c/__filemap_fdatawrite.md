# __filemap_fdatawrite

```
static inline int __filemap_fdatawrite(struct address_space *mapping,
	int sync_mode)
{
	return __filemap_fdatawrite_range(mapping, 0, LLONG_MAX, sync_mode);
}
```

## __filemap_fdatawrite_range

https://github.com/novelinux/linux-4.x.y/blob/master/mm/filemap.c/__filemap_fdatawrite_range.md
