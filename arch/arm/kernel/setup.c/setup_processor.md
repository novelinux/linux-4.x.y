setup_processor
========================================

lookup_processor_type
----------------------------------------

path: arch/arm/kernel/setup.c
```
static void __init setup_processor(void)
{
    struct proc_info_list *list;

    /*
     * locate processor in the list of supported processor
     * types.  The linker builds this table for us from the
     * entries in arch/arm/mm/proc-*.S
     */
     /* read_cpuid_id从CP15的寄存器中读取CPU ID，然后查找到CPU对应的proc_info_list结构体。
      * 然后通过printk打印出CPU的相关信息。
      */
    list = lookup_processor_type(read_cpuid_id());
    if (!list) {
        pr_err("CPU configuration botched (ID %08x), unable to continue.\n",
               read_cpuid_id());
        while (1);
    }

    cpu_name = list->cpu_name;
    __cpu_architecture = __get_cpu_architecture();

#ifdef MULTI_CPU
    processor = *list->proc;
#endif
#ifdef MULTI_TLB
    cpu_tlb = *list->tlb;
#endif
#ifdef MULTI_USER
    cpu_user = *list->user;
#endif
#ifdef MULTI_CACHE
    cpu_cache = *list->cache;
#endif

    pr_info("CPU: %s [%08x] revision %d (ARMv%s), cr=%08lx\n",
        cpu_name, read_cpuid_id(), read_cpuid_id() & 15,
        proc_arch[cpu_architecture()], get_cr());
```

在我们实验环境中打印如下CPU信息:
```
[    0.000000] CPU: ARMv7 Processor [511f06f0] revision 0 (ARMv7), cr=10c5387d
```

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/kernel/head-common.S/lookup_processor_type.md

other
----------------------------------------

```
    snprintf(init_utsname()->machine, __NEW_UTS_LEN + 1, "%s%c",
         list->arch_name, ENDIANNESS);
    snprintf(elf_platform, ELF_PLATFORM_SIZE, "%s%c",
         list->elf_name, ENDIANNESS);
    elf_hwcap = list->elf_hwcap;

    cpuid_init_hwcaps();

#ifndef CONFIG_ARM_THUMB
    elf_hwcap &= ~(HWCAP_THUMB | HWCAP_IDIVT);
#endif
#ifdef CONFIG_MMU
    init_default_cache_policy(list->__cpu_mm_mmu_flags);
#endif
    erratum_a15_798181_init();

    elf_hwcap_fixup();
```

cacheid_init
----------------------------------------

```
    cacheid_init();
    cpu_init();
}
```

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/arch/arm/kernel/setup.c/cacheid_init.md
