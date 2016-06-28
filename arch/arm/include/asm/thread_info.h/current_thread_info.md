current_thread_info
========================================

current_thread_info函数用于获取当前运行线程的thread_info信息.

current_thread_info可获得指向当前执行进程的thread_info实例的指针。其地址可以根据内核栈
指针确定，因为thread_info实例总是位于栈顶。因为每个进程分别使用各自的内核栈，进程到栈的
映射是唯一的。

path: arch/arm/asm/thread_info.h
```
/*
 * how to get the current stack pointer in C
 */
register unsigned long current_stack_pointer asm ("sp");

/*
 * how to get the thread information struct from C
 */
static inline struct thread_info *current_thread_info(void) __attribute_const__;

static inline struct thread_info *current_thread_info(void)
{
    return (struct thread_info *)
        (current_stack_pointer & ~(THREAD_SIZE - 1));
}
```
