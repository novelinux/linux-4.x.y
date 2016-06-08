cpucache_notifier
========================================

path: mm/slab.c
```
static struct notifier_block cpucache_notifier = {
    &cpuup_callback, NULL, 0
};
```