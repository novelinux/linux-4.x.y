cpu_v7_set_pte_ext
========================================

根据ATPCS规则，C语言函数在调用汇编语言时，分别通过r0-r2来依次传递参数。
* r0 - 代表的是pte参数，也即二级页表的地址;
* r1 - 为通过pfn_pte计算出的二级页表项值(对应的物理页面地址);
* r2 - 为0。

path: arch/arm/mm/proc-v7-2level.S
```
/*
 *	cpu_v7_set_pte_ext(ptep, pte)
 *
 *	Set a level 2 translation table entry.
 *
 *	- ptep  - pointer to level 2 translation table entry
 *		  (hardware version is stored at +2048 bytes)
 *	- pte   - PTE value to store
 *	- ext	- value for extended PTE bits
 */
ENTRY(cpu_v7_set_pte_ext)
#ifdef CONFIG_MMU
        # 这里的str指令首先将人r1存入r0所指向的地址，也即填充二级页表项.
	str	r1, [r0]			@ linux version

        # bic位清除指令首先将r1中0x3f0对应的位清0，然后对PTE_TYPE_MASK指定的最后两位清0，
        # 也即对0x3ff指定的最后11位清零,
	bic	r3, r1, #0x000003f0
	bic	r3, r3, #PTE_TYPE_MASK
        # orr按位逻辑或指令通过将r3中的值与r2位或操作放入r3，由于r2的值为0，所以r3的值此时
        # 保持不变。最后的orr将r3的值加上PTE_EXT_AP0权限位，或上2是为了指定当前是小页表(4K)
	orr	r3, r3, r2
	orr	r3, r3, #PTE_EXT_AP0 | 2

	tst	r1, #1 << 4
	orrne	r3, r3, #PTE_EXT_TEX(1)

	eor	r1, r1, #L_PTE_DIRTY
	tst	r1, #L_PTE_RDONLY | L_PTE_DIRTY
	orrne	r3, r3, #PTE_EXT_APX

	tst	r1, #L_PTE_USER
	orrne	r3, r3, #PTE_EXT_AP1

	tst	r1, #L_PTE_XN
	orrne	r3, r3, #PTE_EXT_XN

	tst	r1, #L_PTE_YOUNG
	tstne	r1, #L_PTE_VALID
	eorne	r1, r1, #L_PTE_NONE
	tstne	r1, #L_PTE_NONE
	moveq	r3, #0

 # str指令将最终的硬件PTE页表值存放到低地址的二级页表中。所以硬件使用的二级页表总是位于低地址处，
 # 而高地址处的512项PTE是留给Linux自己使用的。
 ARM(	str	r3, [r0, #2048]! )
 THUMB(	add	r0, r0, #2048 )
 THUMB(	str	r3, [r0] )
	ALT_SMP(W(nop))
	ALT_UP (mcr	p15, 0, r0, c7, c10, 1)		@ flush_pte
#endif
	bx	lr
ENDPROC(cpu_v7_set_pte_ext)
```