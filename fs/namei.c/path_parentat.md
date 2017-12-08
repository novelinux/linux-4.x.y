# path_parentat

```
/* Returns 0 and nd will be valid on success; Retuns error, otherwise. */
static int path_parentat(struct nameidata *nd, unsigned flags,
				struct path *parent)
{
```

## path_init

```
	const char *s = path_init(nd, flags);
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/namei.c/path_init.md

## link_path_walk

```
	int err;
	if (IS_ERR(s))
		return PTR_ERR(s);
	err = link_path_walk(s, nd);
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/namei.c/link_path_walk.md

## complete_walk

```
	if (!err)
		err = complete_walk(nd);
	if (!err) {
		*parent = nd->path;
		nd->path.mnt = NULL;
		nd->path.dentry = NULL;
	}
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/namei.c/complete_walk.md

## terminate_walk

```
	terminate_walk(nd);
	return err;
}
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/namei.c/terminate_walk.md
