switch_tls
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

tp_value就是为了设置TLS register的值,在多线程应用程序，其中一个进程共享相同的地址空间中的
所有线程，还有经常出现需要维护的数据是唯一的一个线程。TLS或线程本地存储，是用于线程抽象的概念。
它是一种快速和有效的方式来存储每个线程的本地数据。线程的本地数据的偏移量是通过TLS寄存器
(H/W或S/W块)，它指向线程各自的线程控制块访问。之前ARM内核，甚至ARM9和ARM11核心的一些不具备
这种TLS注册物理上可用。操作系统（Linux从这里开始）需要效仿的软件。新一代的ARM内核。Cortex-AX起，
确实有这TLS的寄存器可用（CP15）。内核对TLS需要做的事情是能够让用户态程序（通常是nptl——一个pthread
的实现）在某个时刻能够设置线程唯一的基址值到内核的线程信息结构内。

path: arch/arm/include/asm/tls.h
```
#ifdef __ASSEMBLY__
#include <asm/asm-offsets.h>
	.macro switch_tls_none, base, tp, tpuser, tmp1, tmp2
	.endm

	.macro switch_tls_v6k, base, tp, tpuser, tmp1, tmp2
	mrc	p15, 0, \tmp2, c13, c0, 2	@ get the user r/w register
	mcr	p15, 0, \tp, c13, c0, 3		@ set TLS register
	mcr	p15, 0, \tpuser, c13, c0, 2	@ and the user r/w register
	str	\tmp2, [\base, #TI_TP_VALUE + 4] @ save it
	.endm

	.macro switch_tls_v6, base, tp, tpuser, tmp1, tmp2
	ldr	\tmp1, =elf_hwcap
	ldr	\tmp1, [\tmp1, #0]
	mov	\tmp2, #0xffff0fff
	tst	\tmp1, #HWCAP_TLS		@ hardware TLS available?
	streq	\tp, [\tmp2, #-15]		@ set TLS value at 0xffff0ff0
	mrcne	p15, 0, \tmp2, c13, c0, 2	@ get the user r/w register
	mcrne	p15, 0, \tp, c13, c0, 3		@ yes, set TLS register
	mcrne	p15, 0, \tpuser, c13, c0, 2	@ set user r/w register
	strne	\tmp2, [\base, #TI_TP_VALUE + 4] @ save it
	.endm

	.macro switch_tls_software, base, tp, tpuser, tmp1, tmp2
	mov	\tmp1, #0xffff0fff
	str	\tp, [\tmp1, #-15]		@ set TLS value at 0xffff0ff0
	.endm
#endif

#ifdef CONFIG_TLS_REG_EMUL
#define tls_emu		1
#define has_tls_reg		1
#define switch_tls	switch_tls_none
#elif defined(CONFIG_CPU_V6)
#define tls_emu		0
#define has_tls_reg		(elf_hwcap & HWCAP_TLS)
#define switch_tls	switch_tls_v6
#elif defined(CONFIG_CPU_32v6K)
#define tls_emu		0
#define has_tls_reg		1
#define switch_tls	switch_tls_v6k
#else
#define tls_emu		0
#define has_tls_reg		0
#define switch_tls	switch_tls_software
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