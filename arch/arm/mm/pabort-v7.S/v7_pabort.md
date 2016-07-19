v7_pabort
========================================

path: arch/arm/mm/pabort-v7.S
```
#include <linux/linkage.h>
#include <asm/assembler.h>

/*
 * Function: v7_pabort
 *
 * Params  : r2 = pt_regs
 *	   : r4 = address of aborted instruction
 *	   : r5 = psr for parent context
 *
 * Returns : r4 - r11, r13 preserved
 *
 * Purpose : obtain information about current prefetch abort.
 */

	.align	5
ENTRY(v7_pabort)
	mrc	p15, 0, r0, c6, c0, 2		@ get IFAR
	mrc	p15, 0, r1, c5, c0, 1		@ get IFSR
	b	do_PrefetchAbort
ENDPROC(v7_pabort)
```

剩余的工作就是根据以上两个寄存器提取出来的信息，调用相应函数do_PrefetchAbort进行处理。

do_PrefetchAbort
----------------------------------------

https://github.com/novelinux/linux-4.x.y/blob/master/arch/arm/mm/fault.c/do_PrefetchAbort.md
