CPU_PABORT_HANDLER
========================================

path: arch/arm/include/asm/glue-pf.h
```
/*
 *	Prefetch Abort Model
 *	================
 *
 *	We have the following to choose from:
 *	  legacy	- no IFSR, no IFAR
 *	  v6		- ARMv6: IFSR, no IFAR
 *	  v7		- ARMv7: IFSR and IFAR
 */

#undef CPU_PABORT_HANDLER
#undef MULTI_PABORT

#ifdef CONFIG_CPU_PABRT_LEGACY
# ifdef CPU_PABORT_HANDLER
#  define MULTI_PABORT 1
# else
#  define CPU_PABORT_HANDLER legacy_pabort
# endif
#endif

#ifdef CONFIG_CPU_PABRT_V6
# ifdef CPU_PABORT_HANDLER
#  define MULTI_PABORT 1
# else
#  define CPU_PABORT_HANDLER v6_pabort
# endif
#endif
```

v7_pabort
----------------------------------------

```
#ifdef CONFIG_CPU_PABRT_V7
# ifdef CPU_PABORT_HANDLER
#  define MULTI_PABORT 1
# else
#  define CPU_PABORT_HANDLER v7_pabort
# endif
#endif
```

https://github.com/novelinux/linux-4.x.y/blob/master/arch/arm/mm/pabort-v7.S/v7_pabort.md

error
----------------------------------------

```
#ifndef CPU_PABORT_HANDLER
#error Unknown prefetch abort handler type
#endif

#endif
```