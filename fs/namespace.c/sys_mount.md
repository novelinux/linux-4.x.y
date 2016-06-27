sys_mount
========================================

Arguments
----------------------------------------

path: fs/namespace.c
```
SYSCALL_DEFINE5(mount, char __user *, dev_name, char __user *, dir_name,
        char __user *, type, unsigned long, flags, void __user *, data)
{
    int ret;
    char *kernel_type;
    char *kernel_dev;
    unsigned long data_page;

    kernel_type = copy_mount_string(type);
    ret = PTR_ERR(kernel_type);
    if (IS_ERR(kernel_type))
        goto out_type;

    kernel_dev = copy_mount_string(dev_name);
    ret = PTR_ERR(kernel_dev);
    if (IS_ERR(kernel_dev))
        goto out_dev;

    ret = copy_mount_options(data, &data_page);
    if (ret < 0)
        goto out_data;
```

do_mount
----------------------------------------

```
    ret = do_mount(kernel_dev, dir_name, kernel_type, flags,
        (void *) data_page);
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/namespace.c/do_mount.md

Return
----------------------------------------

```
    free_page(data_page);
out_data:
    kfree(kernel_dev);
out_dev:
    kfree(kernel_type);
out_type:
    return ret;
}
```