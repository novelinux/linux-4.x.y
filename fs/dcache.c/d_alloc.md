# d_alloc

```
/**
 * d_alloc	-	allocate a dcache entry
 * @parent: parent of entry to allocate
 * @name: qstr of the name
 *
 * Allocates a dentry. It returns %NULL if there is insufficient memory
 * available. On a success the dentry is returned. The name passed in is
 * copied and the copy passed in may be reused after this call.
 */
struct dentry *d_alloc(struct dentry * parent, const struct qstr *name)
{
	struct dentry *dentry = __d_alloc(parent->d_sb, name);
	if (!dentry)
		return NULL;
	dentry->d_flags |= DCACHE_RCUACCESS;
	spin_lock(&parent->d_lock);
	/*
	 * don't need child lock because it is not subject
	 * to concurrency here
	 */
	__dget_dlock(parent);
	dentry->d_parent = parent;
	list_add(&dentry->d_child, &parent->d_subdirs);
	spin_unlock(&parent->d_lock);

	return dentry;
}
EXPORT_SYMBOL(d_alloc);
```

## __d_alloc

https://github.com/novelinux/linux-4.x.y/blob/master/fs/dcache.c/__d_alloc.md