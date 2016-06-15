NR_OPEN_DEFAULT
========================================

默认情况下，内核允许每个进程打开NR_OPEN_DEFAULT个文件。默认值为BITS_PER_LONG。
因此在32位系统上，允许打开文件的初始数目是32。64位系统可以同时处理64个文件。
如果一个进程试图同时打开更多的文件，内核必须对files_struct中用于管理与进程相关的
所有文件信息的各个成员，分配更多的内存空间。

path: include/linux/fdtable.h
```
/*
 * The default fd array needs to be at least BITS_PER_LONG,
 * as this is the granularity returned by copy_fdset().
 */
#define NR_OPEN_DEFAULT BITS_PER_LONG
```
