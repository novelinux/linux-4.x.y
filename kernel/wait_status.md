linux子进程退出状态值解析：waitpid() status意义解析
========================================


一、和子进程同步
----------------------------------------

在linux系统中，父进程通常需要通过waitpid来等待/获取子进程状态变化情况，而这个主要就是通过waitXXX函数族来实现的，
例如常见的init函数实现的respawn类配置进程(例如getty)、调试器中对子进程状态的获取，shell对同步子进程状态的监控和获取，
以及通常我们工程中使用的子进程和父进程之间的通讯等。
我们在linux下man 一下waitpid，可以看到有下面三个比较常用的函数

```
       #include <sys/types.h>
       #include <sys/wait.h>
       pid_t wait(int *status);
       pid_t waitpid(pid_t pid, int *status, int options);
       int waitid(idtype_t idtype, id_t id, siginfo_t *infop, int options);
```

‘它们的共同特点就是提供给操作系统一个用户态指针，然后由内核来填充这个值，这里子进程的返回值并不是通过waitpid函数本身的返回值决定，
因为waitpid并不总是返回成功，如果传入的pid非法，那么可能返回负数，所以子进程的真正退出情况需要另外提供参数来完成。
可以看到，这个返回值是一个int类型的内存地址，所以父进程和子进程之间所有的状态交互都要通过这个int来表示，
这个int如何编码就比较重要了，和IP地址一样，它是比较紧凑的，或者说是比较拥挤的。

二、子进程通过exit退出
----------------------------------------

这个一般来说相当于正常退出，至少说不是由于不可抗拒的外力导致的退出，例如被SIGKILL杀死，收到SIGPIPE信号的，
它的退出时主动退出，也算是个善终。这类错误码直通内核，然后内核中转在返还给用户态的waitpid，
这条路还算是通畅，但是内核也是经过了简单加工，因为内核的最低8bits是用来供信号使用的，
而真正的exit返回值记录在高8bits，而且只能占用8bits，这意味着如果exit的返回值过大，waitpid并不能够看到，

```
SYSCALL_DEFINE1(exit_group, int, error_code)
{
    do_group_exit((error_code & 0xff) << 8);
    /* NOTREACHED */
    return 0;
}
do_group_exit---.>>>do_exit
tsk->exit_code = code;
```

对于通过exit退出进程，它首先会成为僵尸进程(tsk->state = TASK_DEAD 并且 tsk->exit_state = EXIT_ZOMBIE)，等待父进程通过waitXXX来回收。父进程就通过

SYSCALL_DEFINE3(waitpid, pid_t, pid, int __user *, stat_addr, int, options)
----> SYSCALL_DEFINE4(wait4, pid_t, upid, int __user *, stat_addr, int, options, struct rusage __user *, ru)
----> do_wait ----> do_wait_thread ---> wait_consider_task----> wait_task_zombie

```
    status = (p->signal->flags & SIGNAL_GROUP_EXIT)
        ? p->signal->group_exit_code : p->exit_code;
    if (!retval && wo->wo_stat)
        retval = put_user(status, wo->wo_stat);
```

所以子进程的返回值就是这么确定的，它的低8位为零，次低8位为真正退出码。

[tsecer@Harry waitstat]$ cat exitcode.c

```
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>

int main()
{
pid_t forker;
if(0 == (forker = fork()))
{
        exit(0x12345678);
}else if ((pid_t)0 > forker)
{
           perror("fork faile\n");
} else {
          int status;
          waitpid(forker,&status,0);
         printf("exit status is %x\n",status);
}
}
```

[tsecer@Harry waitstat]$ gcc exitcode.c -o exitcode.exe
[tsecer@Harry waitstat]$ ./exitcode.exe
exit status is 7800           可以看到返回值只有最低6bits生效，其它丢失。
[tsecer@Harry waitstat]$

三、信号导致退出
----------------------------------------

这个也比较常见，应该是仅次于exit退出的一个任务消亡方法。如果不安装信号处理函数，通常的信号都是致命的，
例如段错误SIGSEGV、非法指令SIGILL、管道断裂SIGPIPE、程序流产SIGABORT等，这些父进程也需要知道原因。
在status的低7bits用来保存进程结束时受到的信号，所以信号最多能够有127个，例如MIPS系统。
get_signal_to_deliver ----> do_group_exit(info->si_signo) ---> do_exit(exit_code)
之后的流程和前一个相同。但是在信号退出的时候，这个地方修改了返回值的意义

```
do_group_exit(int exit_code)
{
    struct signal_struct *sig = current->signal;

    BUG_ON(exit_code & 0x80); /* core dumps don't get here */

    if (signal_group_exit(sig))
        exit_code = sig->group_exit_code;
    else if (!thread_group_empty(current)) {
        struct sighand_struct *const sighand = current->sighand;
        spin_lock_irq(&sighand->siglock);
        if (signal_group_exit(sig))
            /* Another thread got here before we took the lock.  */
            exit_code = sig->group_exit_code;
        else {
            sig->group_exit_code = exit_code;
            sig->flags = SIGNAL_GROUP_EXIT;这两个将会影响到最后status的返回值。
            zap_other_threads(current);
        }
        spin_unlock_irq(&sighand->siglock);
    }

    do_exit(exit_code);
    /* NOTREACHED */
}
```

再次把前一节中的赋值操作拷贝一下

```
    status = (p->signal->flags & SIGNAL_GROUP_EXIT)
        ? p->signal->group_exit_code : p->exit_code;此时满足前一个条件，返回值的低7bits为导致进程退出信号数值。
    if (!retval && wo->wo_stat)
        retval = put_user(status, wo->wo_stat);
```

同样是上面代码，在子进程中制造访问异常

```
[tsecer@Harry waitstat]$ cat exitcode.fault.c
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>

int main()
{
pid_t forker;
if(0 == (forker = fork()))
{
    *(int*)0 = 0;
        exit(0x12345678);
}else if ((pid_t)0 > forker)
{
perror("fork faile\n");
} else {
int status;
waitpid(forker,&status,0);
printf("exit status is %x\n",status);
}
}

[tsecer@Harry waitstat]$ gcc exitcode.fault.c -o exitcode.fault.c.exe
[tsecer@Harry waitstat]$ ./exitcode.fault.c.exe
exit status is 8b  低7bits表示导致任务退出的信号数值，SIGSEGV=11，最高一个bit表示是否生成coredump文件。
[tsecer@Harry waitstat]$
coredump文件设置的位置为
int get_signal_to_deliver(siginfo_t *info, struct k_sigaction *return_ka, struct pt_regs *regs, void *cookie)
        if (sig_kernel_coredump(signr)) {
            if (print_fatal_signals)
                print_fatal_signal(regs, info->si_signo);
            /*
             * If it was able to dump core, this kills all
             * other threads in the group and synchronizes with
             * their demise.  If we lost the race with another
             * thread getting here, it set group_exit_code
             * first and our do_group_exit call below will use
             * that value and ignore the one we pass it.
             */
            do_coredump(info->si_signo, info->si_signo, regs);
        }

do_coredump
    if (retval)
        current->signal->group_exit_code |= 0x80;
```

四、进程状态变化
----------------------------------------

一般是进程转换为STOPPED或者CONTINUED，父进程默认会收到这些信号，这一点可以在注册信号处理函数的时候屏蔽掉这种行为，
注册SIGCHLD的时候通过SA_NOCLDSTOP来拒绝当进程变化时接收信号；而父进程默认不会在STOP和CONTINUE的时候唤醒，
需要在waitpid的最后一个参数中分别设置WUNTRACED和WCONTINUED标志。

```
get_signal_to_deliver ---> do_signal_stop
if (!sig->group_stop_count) {
        struct task_struct *t;

        if (!likely(sig->flags & SIGNAL_STOP_DEQUEUED) ||
            unlikely(signal_group_exit(sig)))
            return 0;
        /*
         * There is no group stop already in progress.
         * We must initiate one now.
         */
        sig->group_exit_code = signr;
}
……
    if (notify) {
        read_lock(&tasklist_lock);
        do_notify_parent_cldstop(current, notify);
        read_unlock(&tasklist_lock);
    }
对于waitpid系统调用
static int wait_task_stopped(struct wait_opts *wo,  int ptrace, struct task_struct *p)

    p_code = task_stopped_code(p, ptrace);///return &p->signal->group_exit_code;此处返回前面赋值的信号。
……
    if (!retval && wo->wo_stat)
        retval = put_user((exit_code << 8) | 0x7f, wo->wo_stat);
```

也就是低8bits为0x7f，次低8bits为导致任务STOP的信号，这个信号不仅有SIGSTOP，还有SIGTIN和SIGTOUT（大家可以看一下sig_kernel_stop的实现）。

测试程序

```
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/wait.h>

int main()
{
pid_t forker;
if(0 == (forker = fork()))
{
    setpgrp();
    char buf[0x10];
    while(1) { sleep (1) ;read(0,buf,sizeof(buf));}
    //sleep(10000);
        exit(0x12345678);
}else if ((pid_t)0 > forker)
{
perror("fork faile\n");
} else {
int status;
while (1) {
waitpid(forker,&status,WUNTRACED|WCONTINUED);
printf("exit status is %x\n",status);
}}
}
```

[tsecer@Harry waitstat]$ gcc exitcode.stop.c -o exitcode.stop.c.exe -static
[tsecer@Harry waitstat]$ ./exitcode.stop.c.exe &      后台运行，所以子进程的read触发SIGTTIN信号，其中SIGTTIN在386系统中为21=0x15。
[6] 15452
[tsecer@Harry waitstat]$ exit status is 157f     高byte为信号SIGTTIN，低byte为7f，这个是一个绝对值。

[tsecer@Harry waitstat]$ kill -SIGCONT 15453 这个在FC的31内核没有显示CONTINUE对应的0xffff，在2.6.37中有显示，没有追究原因。
[tsecer@Harry waitstat]$ exit status is 157f

其中WUNTRACED和WCONTINUED分别在2.6.37内核下面位置使用：

```
static int wait_task_continued(struct wait_opts *wo, struct task_struct *p)
{
    int retval;
    pid_t pid;
    uid_t uid;

    if (!unlikely(wo->wo_flags & WCONTINUED))
        return 0;
……
}
static int wait_task_stopped(struct wait_opts *wo,
                int ptrace, struct task_struct *p)
{
    struct siginfo __user *infop;
    int retval, exit_code, *p_code, why;
    uid_t uid = 0; /* unneeded, required by compiler */
    pid_t pid;

    /*
     * Traditionally we see ptrace'd stopped tasks regardless of options.
     */
    if (!ptrace && !(wo->wo_flags & WUNTRACED))
        return 0;
……
}
```

五、C库对返回值的封装
----------------------------------------

为了避免用户直接判断waitpid的返回值，C库定义了一些宏来判断返回值:

```
glibc-2.7\posix\sys\wait.h
# define WEXITSTATUS(status)    __WEXITSTATUS(__WAIT_INT(status))
# define WTERMSIG(status)    __WTERMSIG(__WAIT_INT(status))
# define WSTOPSIG(status)    __WSTOPSIG(__WAIT_INT(status))
# define WIFEXITED(status)    __WIFEXITED(__WAIT_INT(status))
# define WIFSIGNALED(status)    __WIFSIGNALED(__WAIT_INT(status))
# define WIFSTOPPED(status)    __WIFSTOPPED(__WAIT_INT(status))
# ifdef __WIFCONTINUED
#  define WIFCONTINUED(status)    __WIFCONTINUED(__WAIT_INT(status))
glibc-2.7\bits\waitstatus.h
/* Everything extant so far uses these same bits.  */


/* If WIFEXITED(STATUS), the low-order 8 bits of the status.  */
#define    __WEXITSTATUS(status)    (((status) & 0xff00) >> 8)

/* If WIFSIGNALED(STATUS), the terminating signal.  */
#define    __WTERMSIG(status)    ((status) & 0x7f)

/* If WIFSTOPPED(STATUS), the signal that stopped the child.  */
#define    __WSTOPSIG(status)    __WEXITSTATUS(status)

/* Nonzero if STATUS indicates normal termination.  */
#define    __WIFEXITED(status)    (__WTERMSIG(status) == 0)

/* Nonzero if STATUS indicates termination by a signal.  */
#define __WIFSIGNALED(status) \
  (((signed char) (((status) & 0x7f) + 1) >> 1) > 0)

/* Nonzero if STATUS indicates the child is stopped.  */
#define    __WIFSTOPPED(status)    (((status) & 0xff) == 0x7f)

/* Nonzero if STATUS indicates the child continued after a stop.  We only
   define this if <bits/waitflags.h> provides the WCONTINUED flag bit.  */
#ifdef WCONTINUED
# define __WIFCONTINUED(status)    ((status) == __W_CONTINUED)
#endif

/* Nonzero if STATUS indicates the child dumped core.  */
#define    __WCOREDUMP(status)    ((status) & __WCOREFLAG)

/* Macros for constructing status values.  */
#define    __W_EXITCODE(ret, sig)    ((ret) << 8 | (sig))
#define    __W_STOPCODE(sig)    ((sig) << 8 | 0x7f)
#define __W_CONTINUED        0xffff
#define    __WCOREFLAG        0x80
```