DECLARE_BITMAP
========================================

path: include/linux/types.h
```
#define DECLARE_BITMAP(name,bits) \
    unsigned long name[BITS_TO_LONGS(bits)]
```

BITS_TO_LONGS
----------------------------------------

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/include/linux/bitops.h/BIT_XXX.md
