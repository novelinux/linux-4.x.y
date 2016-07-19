pabt_helper
========================================

path: arch/arm/kernel/entry-armv.S
```
	.macro	pabt_helper
	@ PABORT handler takes pt_regs in r2, fault address in r4 and psr in r5
#ifdef MULTI_PABORT
	ldr	ip, .LCprocfns
	mov	lr, pc
	ldr	pc, [ip, #PROCESSOR_PABT_FUNC]
#else
	bl	CPU_PABORT_HANDLER
#endif
	.endm
```

CPU_PABORT_HANDLER
----------------------------------------

https://github.com/novelinux/linux-4.x.y/blob/master/arch/arm/include/asm/glue-pf.h/CPU_PABORT_HANDLER.md
