to_cpumask
========================================

path: include/linux/cpumask.h
```
/**
 * to_cpumask - convert an NR_CPUS bitmap to a struct cpumask *
 * @bitmap: the bitmap
 *
 * There are a few places where cpumask_var_t isn't appropriate and
 * static cpumasks must be used (eg. very early boot), yet we don't
 * expose the definition of 'struct cpumask'.
 *
 * This does the conversion, and can be used as a constant initializer.
 */
#define to_cpumask(bitmap)                        \
    ((struct cpumask *)(1 ? (bitmap)                \
                : (void *)sizeof(__check_is_bitmap(bitmap))))
```

struct cpumask
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/cpumask.h/struct_cpumask.md