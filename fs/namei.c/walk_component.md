# walk_component

在 Kernel 中任何一个常用操作都会有两套以上的策略:

* 其中一个是高效率的;
* 相对而言另一个就是系统开销比较大的。

比如在下面的代码中就能直观的发现 Kernel 会首先尝试 fast，如果失败了才会启动 slow。
其实在我们当前的场景中不止这两种策略，别忘了在这里还有 rcu-walk 和 ref-walk，现在
我们先简单介绍一下 Kernel 在这里进行“路径行走”的策略，让大家有一个感性认识，然后
再进入这几个函数中进行理性分析。首先 Kernel 会在 rcu-walk 模式下进入 lookup_fast
进行尝试，如果失败了那么就尝试就地转入 ref-walk。Kernel 在 ref-walk 模式下会首先在
内存缓冲区查找相应的目标（lookup_fast），如果找不到就启动具体文件系统自己的 lookup
进行查找（lookup_slow）。注意，在 rcu-walk 模式下是不会进入 lookup_slow 的。如果这样
都还找不到的话就一定是是出错了，那就报错返回吧，这时屏幕就会出现喜闻乐见的
“No such file or directory”。

path: fs/namei.c
```
static int walk_component(struct nameidata *nd, int flags)
{
    struct path path;
    struct inode *inode;
    unsigned seq;
    int err;
    /*
     * "." and ".." are special - ".." especially so because it has
     * to be able to know about the current root directory and
     * parent relationships.
     */
    if (unlikely(nd->last_type != LAST_NORM)) {
        err = handle_dots(nd, nd->last_type);
        if (flags & WALK_PUT)
            put_link(nd);
        return err;
    }
```

## lookup_fast

```
    err = lookup_fast(nd, &path, &inode, &seq);
    if (unlikely(err)) {
        if (err < 0)
            return err;
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/namei.c/lookup_fast.md

## lookup_slow

```
        err = lookup_slow(nd, &path);
        if (err < 0)
            return err;
        inode = d_backing_inode(path.dentry);
        seq = 0;    /* we are already out of RCU mode */
        err = -ENOENT;
        if (d_is_negative(path.dentry))
            goto out_path_put;
    }

    if (flags & WALK_PUT)
        put_link(nd);
    err = should_follow_link(nd, &path, flags & WALK_GET, inode, seq);
    if (unlikely(err))
        return err;
    path_to_nameidata(&path, nd);
    nd->inode = inode;
    nd->seq = seq;
    return 0;

out_path_put:
    path_to_nameidata(&path, nd);
    return err;
}
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/namei.c/lookup_slow.md