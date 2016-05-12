DEFINE_PER_CPU_SECTION
========================================

path: include/linux/percpu-defs.h
```
#define DEFINE_PER_CPU_SECTION(type, name, sec)                \
    __PCPU_ATTRS(sec) PER_CPU_DEF_ATTRIBUTES                   \
    __typeof__(type) name
```

__PCPU_ATTRS
----------------------------------------

https://github.com/novelinux/linux-4.x.y/blob/master/include/linux/percpu-defs.h/__PCPU_ATTRS.md
