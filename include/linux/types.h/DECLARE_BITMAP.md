DECLARE_BITMAP
========================================

path: include/linux/types.h
```
#define DECLARE_BITMAP(name,bits) \
    unsigned long name[BITS_TO_LONGS(bits)]
```

BITS_TO_LONGS
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/bitops.h/BIT_XXX.md
