test_slab.ko
========================================

```
root@gemini:/sys/kernel/slab/test_slab_cache # ls
aliases
align
alloc_calls
cache_dma
cpu_partial
cpu_slabs
ctor
destroy_by_rcu
free_calls
hwcache_align
min_partial
object_size
objects
objects_partial
objs_per_slab
order
partial
poison
reclaim_account
red_zone
reserved
sanity_checks
shrink
slab_size
slabs
slabs_cpu_partial
store_user
total_objects
trace
validate
root@gemini:/sys/kernel/slab/test_slab_cache # cat object_size
76
root@gemini:/sys/kernel/slab/test_slab_cache # cat total_objects
42
root@gemini:/sys/kernel/slab/test_slab_cache # cat objs_per_slab
42
root@gemini:/sys/kernel/slab/test_slab_cache # cat objects
10
root@gemini:/sys/kernel/slab/test_slab_cache # cat min_partial
5
root@gemini:/sys/kernel/slab/test_slab_cache # cat objects_partial
10
root@gemini:/sys/kernel/slab/test_slab_cache # cat slab_size
96
root@gemini:/sys/kernel/slab/test_slab_cache # cat slabs
1
```