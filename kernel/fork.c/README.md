fork
========================================

传统的UNIX中用于复制进程的系统调用是fork。但它并不是Linux为此实现的唯一调用，实际上Linux实现了3个:

* 1.fork是重量级调用，因为它建立了父进程的一个完整副本，然后作为子进程执行。
    为减少与该调用相关的工作量，Linux使用了写时复制（copy-on-write）技术.

* 2.vfork类似于fork，但并不创建父进程数据的副本。相反，父子进程之间共享数据。
    这节省了大量CPU时间（如果一个进程操纵共享数据，则另一个会自动注意到）。
    vfork设计用于子进程形成后立即执行execve系统调用加载新程序的情形。在子进程
    退出或开始新程序之前，内核保证父进程处于堵塞状态。引用手册页vfork(2)的文字，
    “非常不幸，Linux从过去复活了这个幽灵”。由于fork使用了写时复制技术，vfork速度
    方面不再有优势，因此应该避免使用它。

* 3.clone产生线程，可以对父子进程之间的共享、复制进行精确控制。

**写时复制**:

内核使用了写时复制（Copy-On-Write，COW）技术，以防止在fork执行时将父进程的所有数据复制到子进程。
该技术利用了下述事实：进程通常只使用了其内存页的一小部分。在调用fork时，内核通常对父进程的每个
内存页，都为子进程创建一个相同的副本。这有两种很不好的负面效应。

* 1.使用了大量内存。
* 2.复制操作耗费很长时间。如果应用程序在进程复制之后使用exec立即加载新程序，那么负面效应会更严重。
    这实际上意味着，此前进行的复制操作是完全多余的，因为进程地址空间会重新初始化，复制的数据不再
    需要了。

内核可以使用技巧规避该问题。并不复制进程的整个地址空间，而是只复制其页表。这样就建立了虚拟地址空间
和物理内存页之间的联系，因此，fork之后父子进程的地址空间指向同样的物理内存页。当然，父子进程不能
允许修改彼此的页，这也是两个进程的页表对页标记了只读访问的原因，即使在普通环境下允许写入也是如此。
假如两个进程只能读取其内存页，那么二者之间的数据共享就不是问题，因为不会有修改。只要一个进程试图
向复制的内存页写入，处理器会向内核报告访问错误（此类错误被称作缺页异常）。内核然后查看额外的内存
管理数据结构，检查该页是否可以用读写模式访问，还是只能以只读模式访问。如果是后者，则必须向进程报告
段错误。缺页异常处理程序的实际实现要复杂得多，因为还必须考虑其他方面的问题，例如换出的页。如果
页表项将一页标记为“只读”，但通常情况下该页应该是可写的，内核可根据此条件来判断该页实际上是COW页。
因此内核会创建该页专用于当前进程的副本，当然也可以用于写操作。COW机制使得内核可以尽可能延迟内存页
的复制，更重要的是，在很多情况下不需要复制。这节省了大量时间。


下面我们以bionic c库中的fork函数为例来讲解fork函数的执行过程:

fork
----------------------------------------

path: bionic/libc/bionic/fork.c
```
int  fork(void)
{
    int ret;
    ...
    ret = __fork();
    ...
    return ret;
}
```

### __fork

path: bionic/libc/arch-arm/syscalls/__fork.S
```
ENTRY(__fork)
    mov     ip, r7          # 将r7寄存器的值保存到ip寄存器中.
    ldr     r7, =__NR_fork  # 将__NR_fork宏表示的值加载到r7寄存器中

    swi     #0 # 触发软中断
    mov     r7, ip
    cmn     r0, #(MAX_ERRNO + 1)
    bxls    lr
    neg     r0, r0
    b       __set_errno
END(__fork)
```

path: kernel/arch/arm/include/asm/unistd.h
```
#define __NR_OABI_SYSCALL_BASE  0x900000

#if defined(__thumb__) || defined(__ARM_EABI__)
#define __NR_SYSCALL_BASE 0
#else
#define __NR_SYSCALL_BASE __NR_OABI_SYSCALL_BASE
#endif

/*
 * This file contains the system call numbers.
 */
#define __NR_restart_syscall  (__NR_SYSCALL_BASE+  0)
...
#define __NR_fork             (__NR_SYSCALL_BASE+  2)
```

* 在较新的EABI规范中,是将系统调用号压入寄存器r7中;
  EABI是什么东西呢? ABI: Application Binary Interface, 应用二进制接口.
* 而在老的OABI中则是执行的swi中断号的方式, 也就是说原来的调用方式(Old ABI)是通过跟随在swi
  指令中的调用号来进行的.

如上面的代码，用swi #0指令即可触发软中断，并切换到内核态(管理模式)。此时CPU就做的事情就是:
* 1.关中断
* 2.将cpsr值写入到spsr_svc中
* 3.将cpsr[5:0]设置成0b10011（svc模式）
* 4.将pc值+4的地址，也就是swi指令的下一行地址写入lr_svc中
* 5.__vectors_start+8写入pc（向量表第三项，系统调用的处理函数）

当使用swi触发软中断的时候将会调用vector_swi处的中断处理函数来处理对应的软件中断.

https://github.com/leeminghao/doc-linux/blob/master/arch/arm/common/swi.md

在linux arm中，会查询sys_call_table跳转表,这个表中存储的是一系列的函数指针,这些
指针就是系统调用函数的指针.

### sys_call_table

path: kernel/arch/arm/kernel/entry-common.S
```
	.type	sys_call_table, #object
ENTRY(sys_call_table)
#include "calls.S"
```

将会从sys_call_table表中取出fork对应在内核态要执行的函数.

path: kernel/arch/arm/kernel/call.S
```
/* 0 */		CALL(sys_restart_syscall)
		CALL(sys_exit)
		CALL(sys_fork_wrapper)
```

### sys_fork_wrapper

path: kernel/arch/arm/kernel/entry-common.S
```
sys_fork_wrapper:
		add	r0, sp, #S_OFF # 指定参数.
		b	sys_fork
ENDPROC(sys_fork_wrapper)
```

最终fork要执行的函数是sys_fork:

### sys_fork

path: kernel/arch/arm/kernel/sys_arm.c
```
/* Fork a new task - this creates a new program thread.
 * This is called indirectly via a small wrapper
 */
asmlinkage int sys_fork(struct pt_regs *regs)
{
#ifdef CONFIG_MMU
	return do_fork(SIGCHLD, regs->ARM_sp, regs, 0, NULL, NULL);
#else
	/* can not support in nommu mode */
	return(-EINVAL);
#endif
}
```

唯一使用的标志是SIGCHLD。这意味着在子进程终止后发送SIGCHLD信号通知父进程。最初，父子进程的
栈地址相同。但如果操作栈地址并写入数据，则COW机制会为每个进程分别创建一个栈副本。如果do_fork成功，
则新建进程的PID作为系统调用的结果返回，否则返回错误码(负值)。

**注意**: 在系统刚启动时sp是在__mmap_switched函数中指定的:

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/arch/arm/kernel/head-common.S/__mmap_switched.md

sys_fork函数最终是调用do_fork来实现一个进程的创建:

### do_fork

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/kernel/fork.c/do_fork.md

Sample
----------------------------------------

path: sample/dac/helloworld.c
```
#include <stdio.h>

int main(int argc, char* argv[])
{
    printf("hello world\n");
    return 0;
}
```

path: sample/fork_exec_helloworld.c
```
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include <fcntl.h>
#include <unistd.h>

int main(int argc, char* argv[])
{
    int pid = fork();

    if (pid < 0) {
        fprintf(stderr, "fork a subprocess error: %d, %s",
                errno, strerror(errno));
        return EXIT_FAILURE;
    } else if (pid == 0) { /* child process */
        printf("execute child process: %d\n", getpid());
        execl("./helloworld", "helloworld", NULL);
        fprintf(stderr, "exec a subprocess error: %d, %s",
                errno, strerror(errno));
    }

    printf("execute parent process: %d\n", getpid());
    /* parent process */
    if (waitpid(pid, NULL, 0) < 0) {
        fprintf(stderr, "wait a subprocess error: %d, %s",
                errno, strerror(errno));
    }

    return EXIT_SUCCESS;
}
```

编译运行:

```
$ gcc helloworld.c -o helloworld
$ ./helloworld
hello world
$ gcc fork_exec_helloworld.c -o fork
$ ./fork
execute parent process: 22355
execute child process: 22356
hello world
```