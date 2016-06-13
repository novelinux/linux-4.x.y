struct rlimit
========================================

Linux提供资源限制(resource limit，rlimit)机制，对进程使用系统
资源施加某些限制。该机制利用了task_struct中的signal_struct中的
rlim数组，数组类型为struct rlimit

rlim_cur
----------------------------------------

path: include/uapi/linux/resource.h
```
struct rlimit {
    __kernel_ulong_t    rlim_cur;
```

进程当前的资源限制，也称之为软限制（softlimit）.

rlim_max
----------------------------------------

```
    __kernel_ulong_t    rlim_max;
};
```

rlim_max是该限制的最大容许值，因此也称之为硬限制（hard limit）。

rlimit
----------------------------------------

系统调用setrlimit来增减当前限制，但不能超出rlim_max指定的值。
getrlimits用于检查当前限制。rlim数组中的位置标识了受限制资源的
类型，这也是内核需要定义预处理器常数，将资源与位置关联起来的
原因。下表列出了可能的常数及其含义:

https://github.com/novelinux/linux-4.x.y/tree/master/include/uapi/linux/resource.h/res/rlimit.png

内核在proc文件系统中对每个进程都包含了对应的一个文件，这样就可以查看当前的rlimit值：

```
root@cancro:/proc/1 # cat limits
Limit                     Soft Limit           Hard Limit           Units
Max cpu time              unlimited            unlimited            seconds
Max file size             unlimited            unlimited            bytes
Max data size             unlimited            unlimited            bytes
Max stack size            8388608              unlimited            bytes
Max core file size        0                    unlimited            bytes
Max resident set          unlimited            unlimited            bytes
Max processes             11668                11668                processes
Max open files            1024                 4096                 files
Max locked memory         67108864             67108864             bytes
Max address space         unlimited            unlimited            bytes
Max file locks            unlimited            unlimited            locks
Max pending signals       11668                11668                signals
Max msgqueue size         819200               819200               bytes
Max nice priority         40                   40
Max realtime priority     0                    0
Max realtime timeout      unlimited            unlimited            us
```
