__lookup_processor_type
========================================

Kernel 代码将所有CPU信息的定义都放到.proc.info.init段中，因此可以认为.proc.info.init段就是一个数组，
每个元素都定义了一个或一种CPU的信息。目前__lookup_processor_type使用该元素的前两个字段
cpuid和mask来匹配当前CPUID，如果满足 CPUID & mask == cpuid，则找到当前cpu的定义并返回。

path: arch/arm/kernel/head-common.S
```
/*
 * Read processor ID register (CP#15, CR0), and look up in the linker-built
 * supported processor list.  Note that we can't use the absolute addresses
 * for the __proc_info lists since we aren't running with the MMU on
 * (and therefore, we are not in the correct address space).  We have to
 * calculate the offset.
 *
 *    r9 = cpuid
 * Returns:
 *    r3, r4, r6 corrupted
 *    r5 = proc_info pointer in physical address space
 *    r9 = cpuid (preserved)
 */
    __CPUINIT
__lookup_processor_type:
    /* adr是相对寻址，它的寻计算结果是将当前PC值加上__lookup_processor_type_data符号与PC的偏移量，
     * 而PC是物理地址，因此r3的结果也是符号__lookup_processor_type_data的物理地址 */
    adr    r3, __lookup_processor_type_data

    /* r5值为__proc_info_bein, r6值为__proc_ino_end，而r4值为.，
     * 也即符号__lookup_processor_type_data的虚拟地址。请注意，在链接期间，__proc_info_begin和
     * __proc_info_end以及.均是虚执地址。
     */
    ldmia  r3, {r4 - r6}

    /* r3为__lookup_processor_type_data的物理地址，
     * r4为__lookup_processor_type_data的虚拟地址.
     * 结果是r3为物理地址与虚拟地址的差值，即PHYS_OFFSET - PAGE_OFFSET。*/
    sub    r3, r3, r4            @ get offset between virt&phys

    /* 将r5和r6转换为__proc_info_begin和__proc_info_end的物理地址 */
    add    r5, r5, r3            @ convert virt addresses to
    add    r6, r6, r3            @ physical address space

    /* 读取r5指向的__proc_info数组元素的CPUID和mask值分别保存到r3和r4寄存器 */
1:  ldmia  r5, {r3, r4}            @ value, mask

    /* 将当前CPUID和mask相与，并与数组元素中的CPUID比较是否相同
     * 若相同，则找到当前CPU的__proc_info定义，r5指向访元素并返回 */
    and    r4, r4, r9            @ mask wanted bits
    teq    r3, r4
    beq    2f

    /* r5指向下一个__proc_info元素 */
    add    r5, r5, #PROC_INFO_SZ        @ sizeof(proc_info_list)

    /* 是否遍历完所有__proc_info元素 */
    cmp    r5, r6
    blo    1b

    /* 找不到则返回NULL */
    mov    r5, #0                @ unknown processor
2:  mov    pc, lr
ENDPROC(__lookup_processor_type)

/*
 * Look in <asm/procinfo.h> for information about the __proc_info structure.
 */
	.align	2
	.type	__lookup_processor_type_data, %object
__lookup_processor_type_data:
	.long	.
	.long	__proc_info_begin
	.long	__proc_info_end
	.size	__lookup_processor_type_data, . - __lookup_processor_type_data
```

这里的执行过程其实比较简单就是在__proc_info_begin和__proc_info_end这个段里面里面去读取
我们注册在里面的proc_info_list这个结构体.

path: arch/arm/kernel/vmlinux.lds.S
```
#define PROC_INFO							\
	. = ALIGN(4);							\
	VMLINUX_SYMBOL(__proc_info_begin) = .;				\
	*(.proc.info.init)						\
	VMLINUX_SYMBOL(__proc_info_end) = .;

        ...

	.text : {			/* Real text segment		*/
                _stext = .;		/* Text and read-only data	*/
                ...
                ARM_CPU_KEEP(PROC_INFO)
	}
...
```

path: arch/arm/include/asm/procinfo.h
```
/*
 * Note!  struct processor is always defined if we're
 * using MULTI_CPU, otherwise this entry is unused,
 * but still exists.
 *
 * NOTE! The following structure is defined by assembly
 * language, NOT C code.  For more information, check:
 *  arch/arm/mm/proc-*.S and arch/arm/kernel/head.S
 */
struct proc_info_list {
	unsigned int		cpu_val;
	unsigned int		cpu_mask;
	unsigned long		__cpu_mm_mmu_flags;	/* used by head.S */
	unsigned long		__cpu_io_mmu_flags;	/* used by head.S */
	unsigned long		__cpu_flush;		/* used by head.S */
	const char		*arch_name;
	const char		*elf_name;
	unsigned int		elf_hwcap;
	const char		*cpu_name;
	struct processor	*proc;
	struct cpu_tlb_fns	*tlb;
	struct cpu_user_fns	*user;
	struct cpu_cache_fns	*cache;
};
```

具体实现根据你使用的cpu的架构在arch/arm/mm/里面找到具体的实现,我们这里的aries是proc-v7.S.
这段汇编看出,指定.proc.info.init段中存储的是一些结构体,定义了V7指令集特定处理器的属性和处理函数.

path: arch/arm/mm/proc-v7.S
```
        ...
	.section ".proc.info.init", #alloc, #execinstr
        ...
	/*
	 * ARM Ltd. Cortex A15 processor.
	 */
	.type	__v7_ca15mp_proc_info, #object
__v7_ca15mp_proc_info:
	.long	0x410fc0f0
	.long	0xff0ffff0
	__v7_proc __v7_ca15mp_setup, hwcaps = HWCAP_IDIV
	.size	__v7_ca15mp_proc_info, . - __v7_ca15mp_proc_info
        ...
```

从System.map中我们可以看到如下信息:

```
c090008c T __proc_info_begin
c090008c t __v7_ca5mp_proc_info
c09000c0 t __v7_ca9mp_proc_info
c09000f4 t __v7_ca7mp_proc_info
c0900128 t __v7_ca15mp_proc_info
c090015c t __v7_proc_info
c0900190 T __proc_info_end
```