struct zonelist
========================================

path: include/linux/mmzone.h
```
/*
 * One allocation request operates on a zonelist. A zonelist
 * is a list of zones, the first one is the 'goal' of the
 * allocation, the other zones are fallback zones, in decreasing
 * priority.
 *
 * If zlcache_ptr is not NULL, then it is just the address of zlcache,
 * as explained above.  If zlcache_ptr is NULL, there is no zlcache.
 * *
 * To speed the reading of the zonelist, the zonerefs contain the zone index
 * of the entry being read. Helper functions to access information given
 * a struct zoneref are
 *
 * zonelist_zone()    - Return the struct zone * for an entry in _zonerefs
 * zonelist_zone_idx()    - Return the index of the zone for an entry
 * zonelist_node_idx()    - Return the index of the node for an entry
 */
struct zonelist {
    struct zonelist_cache *zlcache_ptr;             // NULL or &zlcache
    /* 备用列表必须包括所有结点的所有内存域，因此由MAX_NUMNODES * MAX_NZ_ZONES项组成，
     * 外加一个用于标记列表结束的空指针。
     */
    struct zoneref _zonerefs[MAX_ZONES_PER_ZONELIST + 1];
#ifdef CONFIG_NUMA
    struct zonelist_cache zlcache;                 // optional ...
#endif
};
```

struct zonelist_cache
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/mmzone.h/struct_zonelist_cache.md

struct zoneref
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/mmzone.h/struct_zoneref.md

MAX_ZONES_PER_ZONELIST
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/mmzone.h/MAX_ZONES_PER_ZONELIST.md
