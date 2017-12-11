# filename_parentat

```
static struct filename *filename_parentat(int dfd, struct filename *name,
				unsigned int flags, struct path *parent,
				struct qstr *last, int *type)
{
	int retval;
	struct nameidata nd;

	if (IS_ERR(name))
		return name;
	set_nameidata(&nd, dfd, name);
```

带填充的nameidata结构体（这个结构体在路径行走的过程中，主要用来保存一些临时数据）
我们看到参数里面有一个nameidata结构体，这个结构体在整个路径行走过程中至关重要，所以还是在看
函数之前还是看看这个结构体。定义如下：

https://github.com/novelinux/linux-4.x.y/blob/master/fs/namei.c/struct_nameidata.md

## path_parentat

```
	retval = path_parentat(&nd, flags | LOOKUP_RCU, parent);
	if (unlikely(retval == -ECHILD))
		retval = path_parentat(&nd, flags, parent);
	if (unlikely(retval == -ESTALE))
		retval = path_parentat(&nd, flags | LOOKUP_REVAL, parent);
	if (likely(!retval)) {
		*last = nd.last;
		*type = nd.last_type;
		audit_inode(name, parent->dentry, LOOKUP_PARENT);
	} else {
		putname(name);
		name = ERR_PTR(retval);
	}
	restore_nameidata();
	return name;
}
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/namei.c/path_parentat.md
