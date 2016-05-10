mm_init_cpumask
========================================

path: include/linux/mm_types.h
```
static inline void mm_init_cpumask(struct mm_struct *mm)
{
#ifdef CONFIG_CPUMASK_OFFSTACK
    mm->cpu_vm_mask_var = &mm->cpumask_allocation;
#endif
    cpumask_clear(mm->cpu_vm_mask_var);
}
```