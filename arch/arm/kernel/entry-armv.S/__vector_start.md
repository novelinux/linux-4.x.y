__vector_start
========================================

Linux kernel ARM异常向量表:

__vector_start
----------------------------------------

path: arch/arm/kernel/entry-armv.S中:
```
__vectors_start:
    W(b)    vector_rst
    W(b)    vector_und
    W(ldr)  pc, __vectors_start + 0x1000 @(__stubs_start == vector + 0x1000)
    W(b)    vector_pabt
    W(b)    vector_dabt
    W(b)    vector_addrexcptn
    W(b)    vector_irq
    W(b)    vector_fiq
```

vector_swi
----------------------------------------

这里__vectors_start + 0x1000地址中存的又是vector_swi的地址：

path: arch/arm/kernel/vmlinux.lds.S
```
    /*
     * The vectors and stubs are relocatable code, and the
     * only thing that matters is their relative offsets
     */
    __vectors_start = .;
    .vectors 0 : AT(__vectors_start) {
        *(.vectors)
    }
    . = __vectors_start + SIZEOF(.vectors);
    __vectors_end = .;

    __stubs_start = .;
    .stubs 0x1000 : AT(__stubs_start) {
        *(.stubs)
    }
    . = __stubs_start + SIZEOF(.stubs);
    __stubs_end = .;
```

path: arch/arm/kernel/entry-armv.S
```
    .section .stubs, "ax", %progbits
__stubs_start:
    @ This must be the first word
    .word    vector_swi
```

当使用swi触发软中断的时候将会调用vector_swi处的中断处理函数来处理对应的软件中断.

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/kernel/entry-common.S/vector_swi.md

vector_pabt
----------------------------------------

发生指令预取中止异常.

path: arch/arm/kernel/entry-armv.S
```
/*
 * Prefetch abort dispatcher
 * Enter in ABT mode, spsr = USR CPSR, lr = USR PC
 */
	vector_stub	pabt, ABT_MODE, 4

	.long	__pabt_usr			@  0 (USR_26 / USR_32)
	.long	__pabt_invalid			@  1 (FIQ_26 / FIQ_32)
	.long	__pabt_invalid			@  2 (IRQ_26 / IRQ_32)
	.long	__pabt_svc			@  3 (SVC_26 / SVC_32)
	.long	__pabt_invalid			@  4
	.long	__pabt_invalid			@  5
	.long	__pabt_invalid			@  6
	.long	__pabt_invalid			@  7
	.long	__pabt_invalid			@  8
	.long	__pabt_invalid			@  9
	.long	__pabt_invalid			@  a
	.long	__pabt_invalid			@  b
	.long	__pabt_invalid			@  c
	.long	__pabt_invalid			@  d
	.long	__pabt_invalid			@  e
	.long	__pabt_invalid			@  f
```

### __pabt_usr

通过判断，若发生该异常的指令处于usr模式，则跳转到__pabt_usr函数去执行:

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/kernel/entry-armv.S/__pabt_usr.md
