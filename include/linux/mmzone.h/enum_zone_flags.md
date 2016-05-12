enum zone_flags
========================================

ZONE_RECLAIM_LOCKED
----------------------------------------

在SMP系统上，多个CPU可能试图并发地回收一个内存域。ZONE_RECLAIM_LOCKED标志可防止这种情况：
如果一个CPU在回收某个内存域，则设置该标志。这防止了其他CPU的尝试。

path: include/linux/mmzone.h
```
enum zone_flags {

    ZONE_RECLAIM_LOCKED,        /* prevents concurrent reclaim */
```

ZONE_OOM_LOCKED
----------------------------------------

专用于某种不走运的情况：如果进程消耗了大量的内存，致使必要的操作都无法完成，
那么内核会试图杀死消耗内存最多的进程，以获得更多的空闲页。该标志可以防止多个
CPU同时进行这种操作。

```
    ZONE_OOM_LOCKED,       /* zone is in OOM killer zonelist */
```

----------------------------------------

```
    ZONE_CONGESTED,        /* zone has many dirty pages backed by a congested BDI */
    ZONE_DIRTY,            /* reclaim scanning has recently found
                            * many dirty file pages at the tail
                            * of the LRU.
                            */
    ZONE_WRITEBACK,            /* reclaim scanning has recently found
                     * many pages under writeback
                     */
    ZONE_FAIR_DEPLETED,        /* fair zone policy batch depleted */
};
```
