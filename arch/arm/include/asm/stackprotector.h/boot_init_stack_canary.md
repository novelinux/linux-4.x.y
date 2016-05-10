boot_init_stack_canary
========================================

初始化stack_canary栈,stack_canary的是带防止栈溢出攻击保护的堆栈。当user space的程序通过
int 0x80进入内核空间的时候，CPU自动完成一次堆栈切换，从user space的stack切换到
kernel space的stack。在这个进程exit之前所发生的所有系统调用所使用的kernel stack都是同一个。
kernel stack的大小一般为8192 / sizeof (long);

path: arch/arm/include/asm/stackprotector.h
```
extern unsigned long __stack_chk_guard;

/*
 * Initialize the stackprotector canary value.
 *
 * NOTE: this must only be called from functions that never return,
 * and it must always be inlined.
 */
static __always_inline void boot_init_stack_canary(void)
{
    unsigned long canary;

    /* Try to get a semi random initial value. */
    get_random_bytes(&canary, sizeof(canary));
    canary ^= LINUX_VERSION_CODE;

    current->stack_canary = canary;
    __stack_chk_guard = current->stack_canary;
}
```