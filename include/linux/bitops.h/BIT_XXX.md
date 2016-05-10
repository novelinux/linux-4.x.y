BIT
========================================

path: include/linux/bitops.h
```
#ifdef    __KERNEL__
#define BIT(nr)             (1UL << (nr))
#define BIT_ULL(nr)         (1ULL << (nr))
#define BIT_MASK(nr)        (1UL << ((nr) % BITS_PER_LONG))
#define BIT_WORD(nr)        ((nr) / BITS_PER_LONG)
#define BIT_ULL_MASK(nr)    (1ULL << ((nr) % BITS_PER_LONG_LONG))
#define BIT_ULL_WORD(nr)    ((nr) / BITS_PER_LONG_LONG)
#define BITS_PER_BYTE        8
#define BITS_TO_LONGS(nr)    DIV_ROUND_UP(nr, BITS_PER_BYTE * sizeof(long))
#endif
```

DIV_ROUND_UP
----------------------------------------

DIV_ROUND_UP作用是将n/d，除非整除，否则向上取整。

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/include/linux/kernel.h/DIV_ROUND_UP.md
