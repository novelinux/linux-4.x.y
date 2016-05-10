nodemask_t
========================================

path: include/linux/nodemask.h
```
typedef struct { DECLARE_BITMAP(bits, MAX_NUMNODES); } nodemask_t;
```

DECLARE_BITMAP宏展开后的样子如下所示:

```
typedef struct { unsigned long bits[BITS_TO_LONGS(MAX_NUMNODES)]; } nodemask_t;
```

假设MAX_NUMNODES为1,最终计算结果如下所示:

```
typedef struct { unsigned long bits[1]; } nodemask_t;
```

DECLARE_BITMAP
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/types.h/DECLARE_BITMAP.md

MAX_NUMNODES
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/numa.h/MAX_NUMNODES.md
