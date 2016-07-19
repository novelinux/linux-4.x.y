__pabt_usr
========================================

path: arch/arm/kernel/entry-armv.S
```
	.align	5
__pabt_usr:
	usr_entry
	mov	r2, sp				@ regs
	pabt_helper
 UNWIND(.fnend		)
```

pabt_helper
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/kernel/entry-armv.S/pabt_helper.md
