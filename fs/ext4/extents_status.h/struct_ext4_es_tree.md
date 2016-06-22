struct ext4_es_tree
========================================

root
----------------------------------------

path: fs/ext4/extents_status.h
```
struct ext4_es_tree {
    struct rb_root root;
```

cache_es
----------------------------------------

```
    struct extent_status *cache_es;    /* recently accessed extent */
};
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/ext4/extents_status.h/struct_extent_status.md