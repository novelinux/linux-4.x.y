path_openat
========================================

Arguments
----------------------------------------

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

get_empty_filp
----------------------------------------

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

path_init
----------------------------------------

```
    s = path_init(nd, flags);
    if (IS_ERR(s)) {
        put_filp(file);
        return ERR_CAST(s);
    }
```

link_path_walk
----------------------------------------

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
    terminate_walk(nd);
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