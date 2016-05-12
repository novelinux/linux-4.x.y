__PCPU_ATTRS
========================================

path: include/linux/percpu-defs.h
```
/*
 * Base implementations of per-CPU variable declarations and definitions, where
 * the section in which the variable is to be placed is provided by the
 * 'sec' argument.  This may be used to affect the parameters governing the
 * variable's storage.
 *
 * NOTE!  The sections for the DECLARE and for the DEFINE must match, lest
 * linkage errors occur due the compiler generating the wrong code to access
 * that section.
 */
#define __PCPU_ATTRS(sec)                                          \
    __percpu __attribute__((section(PER_CPU_BASE_SECTION sec)))    \
    PER_CPU_ATTRIBUTES
```
