current
========================================

current宏用户获取当前运行进程的struct task信息.

path: include/asm-generic/current.h
```
#define get_current() (current_thread_info()->task)
#define current get_current()
```

current_tread_info
----------------------------------------

### ARM

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/include/asm/thread_info.h/current_thread_info.md
