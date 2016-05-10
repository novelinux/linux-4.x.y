set_tls
========================================

进程中的全局变量与函数内定义的静态(static)变量，是各个线程都可以访问的共享变量。在一个线程修改
的内存内容，对所有线程都生效。这是一个优点也是一个缺点。说它是优点，线程的数据交换变得非常快捷。
说它是缺点，一个线程死掉了，其它线程也性命不保; 多个线程访问共享数据，需要昂贵的同步开销，也
容易造成同步相关的BUG。如果需要在一个线程内部的各个函数调用都能访问、但其它线程不能访问的变量
（被称为static memory local to a thread 线程局部静态变量），就需要新的机制来实现。这就是TLS。
线程局部存储在不同的平台有不同的实现，可移植性不太好。幸好要实现线程局部存储并不难，最简单的
办法就是建立一个全局表，通过当前线程ID去查询相应的数据，因为各个线程的ID不同，查到的数据自然
也不同了。
它主要是为了避免多个线程同时访存同一全局变量或者静态变量时所导致的冲突，尤其是多个线程同时需要
修改这一变量时。为了解决这个问题，我们可以通过TLS机制，为每一个使用该全局变量的线程都提供一个
变量值的副本，每一个线程均可以独立地改变自己的副本，而不会和其它线程的副本冲突。从线程的角度看，
就好像每一个线程都完全拥有该变量。而从全局变量的角度上来看，就好像一个全局变量被克隆成了多份副本，
而每一份副本都可以被一个线程独立地改变。

path: arch/arm/kernel/include/asm/tls.h
```
#ifdef __ASSEMBLY__
    .macro set_tls_none, tp, tmp1, tmp2
    .endm

    .macro set_tls_v6k, tp, tmp1, tmp2
    mcr    p15, 0, \tp, c13, c0, 3        @ set TLS register
    mov    \tmp1, #0
    mcr    p15, 0, \tmp1, c13, c0, 2    @ clear user r/w TLS register
    .endm

    .macro set_tls_v6, tp, tmp1, tmp2
    ldr    \tmp1, =elf_hwcap
    ldr    \tmp1, [\tmp1, #0]
    mov    \tmp2, #0xffff0fff
    tst    \tmp1, #HWCAP_TLS        @ hardware TLS available?
    mcrne    p15, 0, \tp, c13, c0, 3        @ yes, set TLS register
    movne    \tmp1, #0
    mcrne    p15, 0, \tmp1, c13, c0, 2    @ clear user r/w TLS register
    streq    \tp, [\tmp2, #-15]        @ set TLS value at 0xffff0ff0
    .endm

    .macro set_tls_software, tp, tmp1, tmp2
    mov    \tmp1, #0xffff0fff
    str    \tp, [\tmp1, #-15]        @ set TLS value at 0xffff0ff0
    .endm
#endif

#ifdef CONFIG_TLS_REG_EMUL
#define tls_emu        1
#define has_tls_reg        1
#define set_tls        set_tls_none
#elif defined(CONFIG_CPU_V6)
#define tls_emu        0
#define has_tls_reg        (elf_hwcap & HWCAP_TLS)
#define set_tls        set_tls_v6
#elif defined(CONFIG_CPU_32v6K)
#define tls_emu        0
#define has_tls_reg        1
#define set_tls        set_tls_v6k
#else
#define tls_emu        0
#define has_tls_reg        0
#define set_tls        set_tls_software
#endif
```

aries
----------------------------------------

```
CONFIG_CPU_V7=y
CONFIG_CPU_32v6K=y
CONFIG_CPU_32v7=y
```

对于aries平台，对应set_tls的实现为set_tls_v6k