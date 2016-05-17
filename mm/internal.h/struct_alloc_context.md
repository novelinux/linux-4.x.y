struct alloc_context
========================================

path: mm/internal.h
```
/*
 * Structure for holding the mostly immutable allocation parameters passed
 * between functions involved in allocations, including the alloc_pages*
 * family of functions.
 *
 * nodemask, migratetype and high_zoneidx are initialized only once in
 * __alloc_pages_nodemask() and then never change.
 *
 * zonelist, preferred_zone and classzone_idx are set first in
 * __alloc_pages_nodemask() for the fast path, and might be later changed
 * in __alloc_pages_slowpath(). All other functions pass the whole strucure
 * by a const pointer.
 */
struct alloc_context {
       struct zonelist *zonelist;
       nodemask_t *nodemask;
       struct zone *preferred_zone;
       int classzone_idx;
       int migratetype;
       enum zone_type high_zoneidx;
};
```