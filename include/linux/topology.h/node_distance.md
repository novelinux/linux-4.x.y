node_distance
========================================

path: include/linux/topology.h
```
/* Conform to ACPI 2.0 SLIT distance definitions */
#define LOCAL_DISTANCE         10
#define REMOTE_DISTANCE        20
#ifndef node_distance
#define node_distance(from,to)    ((from) == (to) ? LOCAL_DISTANCE : REMOTE_DISTANCE)
#endif
```
