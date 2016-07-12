randomize_va_space
========================================

----------------------------------------

randomize_va_space决定是否启用进程地址空间随机化机制。通常情况下都是启用的.
定义如下所示:

path: include/linux/mm.h
```
#ifndef CONFIG_MMU
#define randomize_va_space 0
#else
extern int randomize_va_space;
#endif
```

此外，用户可以通过"/proc/sys/kernel/randomize_va_space"文件来停用改特性.
