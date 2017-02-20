# filemap_write_and_wait_range

```
int filemap_write_and_wait(struct address_space *mapping)
{
	int err = 0;

	if (mapping->nrpages) {
		err = filemap_fdatawrite(mapping);
		/*
		 * Even if the above returned error, the pages may be
		 * written partially (e.g. -ENOSPC), so we wait for it.
		 * But the -EIO is special case, it may indicate the worst
		 * thing (e.g. bug) happened, so we avoid waiting for it.
		 */
		if (err != -EIO) {
			int err2 = filemap_fdatawait(mapping);
			if (!err)
				err = err2;
		}
	} else {
		err = filemap_check_errors(mapping);
	}
	return err;
}
EXPORT_SYMBOL(filemap_write_and_wait);
```

## filemap_fdatawrite

https://github.com/novelinux/linux-4.x.y/blob/master/mm/filemap.c/filemap_fdatawrite.md

## filemap_fdatawait