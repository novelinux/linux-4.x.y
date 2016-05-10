set_cpu_online
========================================

path: kernel/cpu.c
```
void set_cpu_online(unsigned int cpu, bool online)
{
    if (online) {
        cpumask_set_cpu(cpu, to_cpumask(cpu_online_bits));
        cpumask_set_cpu(cpu, to_cpumask(cpu_active_bits));
    } else {
        cpumask_clear_cpu(cpu, to_cpumask(cpu_online_bits));
    }
}
```

to_cpumask
----------------------------------------

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/include/linux/cpumask.h/to_cpumask.md

cpu_online_bits
----------------------------------------

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/kernel/cpu.c/cpu_oneline_bits.md

cpumask_set_cpu
----------------------------------------

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/include/linux/cpumask.h/cpumask_set_cpu.md