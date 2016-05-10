cpu_oneline_bits
========================================

path: kernel/cpu.c
```
static DECLARE_BITMAP(cpu_online_bits, CONFIG_NR_CPUS) __read_mostly;
```

DECLARE_BITMAP宏展开后的样子如下所示:

```
static unsigned long cpu_online_bits[1] __read_mostly;
```

DECLARE_BITMAP
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/types.h/DECLARE_BITMAP.md

CONFIG_NR_CPUS
----------------------------------------

与多处理相关的宏定义，表示CPU的个数.

### aries

```
CONFIG_NR_CPUS=4
```