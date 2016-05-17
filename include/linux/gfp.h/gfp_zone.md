gfp_zone
========================================

path: include/linux/gfp.h
```
static inline enum zone_type gfp_zone(gfp_t flags)
{
    enum zone_type z;
    int bit = (__force int) (flags & GFP_ZONEMASK);

    z = (GFP_ZONE_TABLE >> (bit * ZONES_SHIFT)) &
                     ((1 << ZONES_SHIFT) - 1);
    VM_BUG_ON((GFP_ZONE_BAD >> bit) & 1);
    return z;
}
```

GFP_ZONEMASK
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/gfp.h/mask.md

GFP_ZONE_TABLE
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/gfp.h/GFP_ZONE_TABLE.md
