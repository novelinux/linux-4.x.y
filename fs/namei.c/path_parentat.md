# path_parentat

```
/* Returns 0 and nd will be valid on success; Retuns error, otherwise. */
static int path_parentat(struct nameidata *nd, unsigned flags,
				struct path *parent)
{
```

## path_init

首先是path_init函数，顾名思义就是初始化path函数，我们前面说了整个路径查找的过程其实就是填充
nameidata的过程，所以这个函数肯定就是初始化nameidata，

```
	const char *s = path_init(nd, flags);
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/namei.c/path_init.md

## link_path_walk

然后是就函数link_path_walk，这个函数是整个路径名查找过程的核心功能实现函数，经过这个函数，
我们就找到了路径中的最后一个目录的dentry和inode信息了。

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
