cpumask_set_cpu
========================================

path: include/linux/cpumask.h
```
/**
 * cpumask_set_cpu - set a cpu in a cpumask
 * @cpu: cpu number (< nr_cpu_ids)
 * @dstp: the cpumask pointer
 */
static inline void cpumask_set_cpu(unsigned int cpu, struct cpumask *dstp)
{
    set_bit(cpumask_check(cpu), cpumask_bits(dstp));
}
```

cpumask_check
----------------------------------------

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/include/linux/cpumask.h/cpumask_check.md

cpumask_bits
----------------------------------------

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/include/linux/cpumask.h/cpumask_bits.md

set_bit
----------------------------------------

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/include/asm-generic/bitops/atomic.h/set_bit.md
