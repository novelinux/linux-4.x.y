mount_nodev
========================================

Arguments
----------------------------------------

path: fs/super.c
```
struct dentry *mount_nodev(struct file_system_type *fs_type,
    int flags, void *data,
    int (*fill_super)(struct super_block *, void *, int))
{
    int error;
```

sget
----------------------------------------

```
    struct super_block *s = sget(fs_type, NULL, set_anon_super, flags, NULL);

    if (IS_ERR(s))
        return ERR_CAST(s);
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/super.c/sget.md

fill_super
----------------------------------------

```
    error = fill_super(s, data, flags & MS_SILENT ? 1 : 0);
    if (error) {
        deactivate_locked_super(s);
        return ERR_PTR(error);
    }
    s->s_flags |= MS_ACTIVE;
    return dget(s->s_root);
}
EXPORT_SYMBOL(mount_nodev);
```