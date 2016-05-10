smp_prepare_boot_cpu
========================================

path: arch/arm/kernel/smp.c
```
void __init smp_prepare_boot_cpu(void)
{
    set_my_cpu_offset(per_cpu_offset(smp_processor_id()));
}
```