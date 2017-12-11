# path_openat

## Arguments

path: fs/namei.c
```
static struct file *path_openat(struct nameidata *nd,
            const struct open_flags *op, unsigned flags)
{
    const char *s;
    struct file *file;
    int opened = 0;
    int error;
```

## get_empty_filp

获取一个空的struct file结构.

```
    file = get_empty_filp();
    if (IS_ERR(file))
        return file;

    file->f_flags = op->open_flag;

    if (unlikely(file->f_flags & __O_TMPFILE)) {
        error = do_tmpfile(nd, flags, op, file, &opened);
        goto out2;
    }
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/file_table.c/get_empty_filp.md

## path_init

```
    s = path_init(nd, flags);
    if (IS_ERR(s)) {
        put_filp(file);
        return ERR_CAST(s);
    }
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/namei.c/path_init.md

## walk

为什么link_path_walk和do_last的代码如此冗长？令人遗憾的是，查找与给定文件名相关的inode比初看起来
复杂得多，而由于必须考虑下列因素，造成了更多的困难。

* 一个文件可能通过符号链接引用另一个文件，查找代码必须考虑到这种可能性，能够识别出链接，
  并在相应的处理后跳出循环;
* 必须检测装载点，而后据此重定向查找操作;
* 在通向目标文件名的路径上，必须检查所有目录的访问权限。进程必须有适当的权限，否则操作将终止，
  并给出错误信息;
* 格式奇怪但正确的名称，如/./usr/bin/../local/././bin//emacs，必须能够正确地解析.

```
    while (!(error = link_path_walk(s, nd)) &&
        (error = do_last(nd, file, op, &opened)) > 0) {
        nd->flags &= ~(LOOKUP_OPEN|LOOKUP_CREATE|LOOKUP_EXCL);
        s = trailing_symlink(nd);
        if (IS_ERR(s)) {
            error = PTR_ERR(s);
            break;
        }
    }
```

### link_path_walk

https://github.com/novelinux/linux-4.x.y/blob/master/fs/namei.c/link_path_walk.md

### do_last

https://github.com/novelinux/linux-4.x.y/blob/master/fs/namei.c/do_last.md

### trailing_symlink

### terminate_walk

```
    terminate_walk(nd);
```

## out2

```
out2:
    if (!(opened & FILE_OPENED)) {
        BUG_ON(!error);
        put_filp(file);
    }
    if (unlikely(error)) {
        if (error == -EOPENSTALE) {
            if (flags & LOOKUP_RCU)
                error = -ECHILD;
            else
                error = -ESTALE;
        }
        file = ERR_PTR(error);
    }
    return file;
}
```