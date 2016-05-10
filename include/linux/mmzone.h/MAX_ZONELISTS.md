MAX_ZONELISTS
========================================

path: include/linux/mmzone.h
```
#ifdef CONFIG_NUMA

/*
 * The NUMA zonelists are doubled because we need zonelists that restrict the
 * allocations to a single node for __GFP_THISNODE.
 *
 * [0]    : Zonelist with fallback
 * [1]    : No fallback (__GFP_THISNODE)
 */
#define MAX_ZONELISTS 2

...

#else
#define MAX_ZONELISTS 1
...
#endif
```