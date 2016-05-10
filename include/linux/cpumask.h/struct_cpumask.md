struct cpumask
========================================

path: include/linux/cpumask.h
```
/* Don't assign or return these: may not be this big! */
typedef struct cpumask { DECLARE_BITMAP(bits, NR_CPUS); } cpumask_t;
```