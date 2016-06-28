init_task
========================================

init_task
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/init/init_task.c/init_task.md

init_thread_union
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/init/init_task.c/init_thread_union.md

Kernel Stack
----------------------------------------

```
|----------------------------| 0xc04ce000
|        thread_info         |
|----------------------------|
|                            |
|                            |
|                            |
|                            |
|----------------------------|
|     [struct pt_regs]       |
|----------------------------| 0xc04cfff8 (sp)
|           8Byte            |
|----------------------------|
```

有关init_task内核栈的说明:

在__mmap_switched函数中将sp寄存器的值设置为init_thread_union + THREAD_START_SP(8K-8),
也就是上图0xc04cfff8位置处,这是因为内核经过使用汇编语言进行一系列简单的初始化工作之后
将要跳转到C语言环境调用start_kernel函数去执行,因为C语言是一种基于栈的调用语言必须将sp
寄存器指向一段栈内存空间，在这里就是init_task的内核栈,使用gdb调试信息如下:

将断点设置在start_kernel函数入口出.
```
Breakpoint 1, start_kernel () at /home/liminghao/big/leeminghao/yudatun-qemu/kernel/linux-4.3/init/main.c:498
498        {
(gdb) p/x $sp
$1 = 0xc04cfff8
(gdb) p/x $pc
$2 = 0xc04a6918
(gdb) p/x &init_thread_union
$3 = 0xc04ce000
(gdb) disas $pc
Dump of assembler code for function start_kernel:
=> 0xc04a6918 <+0>:    push         {r4, r5, r6, r7, r8, r9, lr}
   0xc04a691c <+4>:    sub          sp, sp, #28 # 接下来的代码就要对栈进行操作.
# 接下来执行几条start_kernel的汇编指令，查看sp寄存器值如下所示:
(gdb) ni
0xc04a691c      498     {
(gdb) p/x $sp
$8 = 0xc04cffdc
(gdb) ni
507     set_task_stack_end_magic(&init_task);
(gdb) p/x $sp
$9 = 0xc04cffc0
(gdb) b kernel_thread
Breakpoint 3 at 0xc001ec2c: file /home/liminghao/big/leeminghao/yudatun-qemu/kernel/linux-4.3/kernel/fork.c, line 1787.
(gdb) c
Continuing.

Breakpoint 3, kernel_thread (fn=0xc0385f54 <kernel_init>, arg=0x0 <__vectors_start>, flags=512) at /home/liminghao/big/leeminghao/yudatun-qemu/kernel/linux-4.3/kernel/fork.c:1787
1787          return _do_fork(flags|CLONE_VM|CLONE_UNTRACED, (unsigned long)fn,
(gdb) s
_do_fork (clone_flags=8389376, stack_start=3224919892, stack_size=0, parent_tidptr=0x0 <__vectors_start>, child_tidptr=0x0 <__vectors_start>, tls=0)
    at /home/liminghao/big/leeminghao/yudatun-qemu/kernel/linux-4.3/kernel/fork.c:1714
1714    if (!(clone_flags & CLONE_UNTRACED)) {
(gdb) p/x $sp
$1 = 0xc04cff68 # 这里依旧使用的是init_task的内核栈
```
