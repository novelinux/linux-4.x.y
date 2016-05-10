early_paging_init
========================================

path: arch/arm/mm/mmu.c
```
#ifdef CONFIG_ARM_LPAE
/*
 * early_paging_init() recreates boot time page table setup, allowing machines
 * to switch over to a high (>4G) address space on LPAE systems
 */


#else

void __init early_paging_init(const struct machine_desc *mdesc,
                  struct proc_info_list *procinfo)
{
    if (mdesc->init_meminfo)
        mdesc->init_meminfo();
}

#endif
```
