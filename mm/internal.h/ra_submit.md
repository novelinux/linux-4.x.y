## ra_submit

```
/*
 * Submit IO for the read-ahead request in file_ra_state.
 */
static inline unsigned long ra_submit(struct file_ra_state *ra,
		struct address_space *mapping, struct file *filp)
{
	return __do_page_cache_readahead(mapping, filp,
					ra->start, ra->size, ra->async_size);
}
```

[__do_page_cache_readahead](../__do_page_cache_readahead.md)