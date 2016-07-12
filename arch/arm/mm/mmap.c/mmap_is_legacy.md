mmap_is_legacy
========================================

如果用户通过/proc/sys/kernel/legacy_va_layout给出明确的指示，或者要
执行行为不同的UNIX变体编译,需要为二进制文件创建旧的进程空间布局, 或者栈
可以无线增长，则系统会选择旧的布局。这使得很难确定栈的下界，亦或者是mmap
区域的上界:

path: arch/arm/mm/mmap.c
```
static int mmap_is_legacy(void)
{
    if (current->personality & ADDR_COMPAT_LAYOUT)
        return 1;

    if (rlimit(RLIMIT_STACK) == RLIM_INFINITY)
        return 1;

    return sysctl_legacy_va_layout;
}
```

mmap_is_legacy等于1表示使用经典布局:

https://github.com/novelinux/linux-4.x.y/tree/master/mm/mmap.c/res/old_layout.jpg

mmap_is_legacy等于0表示使用新的布局:

https://github.com/novelinux/linux-4.x.y/tree/master/mm/mmap.c/res/new_layout.jpg
