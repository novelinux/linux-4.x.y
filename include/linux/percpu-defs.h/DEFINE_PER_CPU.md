DEFINE_PER_CPU
========================================

path: include/linux/percpu-defs.h
```
#define DEFINE_PER_CPU(type, name)                    \
    DEFINE_PER_CPU_SECTION(type, name, "")
```

DEFINE_PER_CPU_SECTION
----------------------------------------

https://github.com/novelinux/linux-4.x.y/blob/master/include/linux/percpu-defs.h/DEFINE_PER_CPU_SECTION.md