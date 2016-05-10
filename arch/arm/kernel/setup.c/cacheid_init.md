cacheid_init
========================================

path: arch/arm/kernel/setup.c
```
static void __init cacheid_init(void)
{
    unsigned int arch = cpu_architecture();

    if (arch == CPU_ARCH_ARMv7M) {
        cacheid = 0;
    } else if (arch >= CPU_ARCH_ARMv6) {
        unsigned int cachetype = read_cpuid_cachetype();
        if ((cachetype & (7 << 29)) == 4 << 29) {
            /* ARMv7 register format */
            arch = CPU_ARCH_ARMv7;
            cacheid = CACHEID_VIPT_NONALIASING;
            switch (cachetype & (3 << 14)) {
            case (1 << 14):
                cacheid |= CACHEID_ASID_TAGGED;
                break;
            case (3 << 14):
                cacheid |= CACHEID_PIPT;
                break;
            }
        } else {
            arch = CPU_ARCH_ARMv6;
            if (cachetype & (1 << 23))
                cacheid = CACHEID_VIPT_ALIASING;
            else
                cacheid = CACHEID_VIPT_NONALIASING;
        }
        if (cpu_has_aliasing_icache(arch))
            cacheid |= CACHEID_VIPT_I_ALIASING;
    } else {
        cacheid = CACHEID_VIVT;
    }

    pr_info("CPU: %s data cache, %s instruction cache\n",
        cache_is_vivt() ? "VIVT" :
        cache_is_vipt_aliasing() ? "VIPT aliasing" :
        cache_is_vipt_nonaliasing() ? "PIPT / VIPT nonaliasing" : "unknown",
        cache_is_vivt() ? "VIVT" :
        icache_is_vivt_asid_tagged() ? "VIVT ASID tagged" :
        icache_is_vipt_aliasing() ? "VIPT aliasing" :
        icache_is_pipt() ? "PIPT" :
        cache_is_vipt_nonaliasing() ? "VIPT nonaliasing" : "unknown");
}
```

read_cpuid_cachetype和cpu_architecture分别获取cachetype和arch，根据它们确定cacheid并打印输出。

```
[    0.000000] CPU: PIPT / VIPT nonaliasing data cache, PIPT instruction cache
```