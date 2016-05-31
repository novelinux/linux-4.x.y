pkmap_count
========================================

pkmap_count是一容量为LAST_PKMAP的整数数组，其中每个元素都对应于一个持久映射页。它实际上是被
映射页的一个使用计数器，语义不太常见。该计数器计算了内核使用该页的次数加1。

如果计数器值为2，则内核中只有一处使用该映射页。计数器值为5表示有4处使用。一般地说，
计数器值为n代表内核中有n-1处使用该页。和通常的使用计数器一样，0意味着相关的页没有使用。
计数器值1有特殊语义。这表示该位置关联的页已经映射，但由于CPU的TLB没有更新而无法使用，
此时访问该页，或者失败，或者会访问到一个不正确的地址。

path: mm/highmem.c
```
static int pkmap_count[LAST_PKMAP];
```

LAST_PKMAP
----------------------------------------

### ARM

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/include/asm/highmem.h/LAST_PKMAP.md
