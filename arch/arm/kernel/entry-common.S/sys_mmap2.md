sys_mmap2
========================================

path: arch/arm/kernel/entry-common.S
```
/*
 * Note: off_4k (r5) is always units of 4K.  If we can't do the requested
 * offset, we return EINVAL.
 */
sys_mmap2:
#if PAGE_SHIFT > 12
		tst	r5, #PGOFF_MASK
		moveq	r5, r5, lsr #PAGE_SHIFT - 12
		streq	r5, [sp, #4]
		beq	sys_mmap_pgoff
		mov	r0, #-EINVAL
		ret	lr
#else
		str	r5, [sp, #4]
		b	sys_mmap_pgoff
#endif
ENDPROC(sys_mmap2)
```

sys_mmap_pgoff
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/mmap.c/sys_mmap_pgoff.md
