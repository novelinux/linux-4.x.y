nodes_clear
========================================

path: include/linux/nodemask.h
```
#define nodes_clear(dst) __nodes_clear(&(dst), MAX_NUMNODES)
static inline void __nodes_clear(nodemask_t *dstp, unsigned int nbits)
{
        bitmap_zero(dstp->bits, nbits);
}
```

nodemask_t
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/nodemask.h/nodemask_t.md
