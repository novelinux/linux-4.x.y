populate_rootfs
========================================

path: init/initramfs.c
```
static int __init populate_rootfs(void)
{
    char *err = unpack_to_rootfs(__initramfs_start, __initramfs_size);
    if (err)
        panic("%s", err); /* Failed to decompress INTERNAL initramfs */
    if (initrd_start) {
#ifdef CONFIG_BLK_DEV_RAM
        int fd;
        printk(KERN_INFO "Trying to unpack rootfs image as initramfs...\n");
        err = unpack_to_rootfs((char *)initrd_start,
            initrd_end - initrd_start);
        if (!err) {
            free_initrd();
            goto done;
        } else {
            clean_rootfs();
            unpack_to_rootfs(__initramfs_start, __initramfs_size);
        }
        printk(KERN_INFO "rootfs image is not initramfs (%s)"
                "; looks like an initrd\n", err);
        fd = sys_open("/initrd.image",
                  O_WRONLY|O_CREAT, 0700);
        if (fd >= 0) {
            ssize_t written = xwrite(fd, (char *)initrd_start,
                        initrd_end - initrd_start);

            if (written != initrd_end - initrd_start)
                pr_err("/initrd.image: incomplete write (%zd != %ld)\n",
                       written, initrd_end - initrd_start);

            sys_close(fd);
            free_initrd();
        }
    done:
#else
        printk(KERN_INFO "Unpacking initramfs...\n");
        err = unpack_to_rootfs((char *)initrd_start,
            initrd_end - initrd_start);
        if (err)
            printk(KERN_EMERG "Initramfs unpacking failed: %s\n", err);
        free_initrd();
#endif
        /*
         * Try loading default modules from initramfs.  This gives
         * us a chance to load before device_initcalls.
         */
        load_default_modules();
    }
    return 0;
}
```

rootfs_initcall
----------------------------------------

```
rootfs_initcall(populate_rootfs);
```

https://github.com/novelinux/linux-4.x.y/blob/master/include/linux/init.h/rootfs_initcall.md

经过rootfs_initcall扩展之后populate_rootfs如下所示:

```
ffffffc0018099b0 T __initcall5_start
...
ffffffc001809a98 t __initcall_populate_rootfsrootfs
ffffffc001809aa0 T __initcall6_start
```

最终会在函数do_initcalls函数中调用该函数.
