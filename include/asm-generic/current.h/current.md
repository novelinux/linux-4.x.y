current
========================================

current宏用户获取当前运行进程的struct task信息.
current给出了当前进程task_struct实例的地址。该函数在源代码中出现非常频繁。该地址可以使用
current_thread_info()确定：current = current_thread_info()->task。

path: include/asm-generic/current.h
```
#define get_current() (current_thread_info()->task)
#define current get_current()
```

current_tread_info
----------------------------------------

### ARM

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/include/asm/thread_info.h/current_thread_info.md
