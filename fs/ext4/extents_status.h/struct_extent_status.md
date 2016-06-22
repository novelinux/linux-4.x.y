struct extent_status
========================================

path: fs/ext4/extents_status.h
```
struct extent_status {
    struct rb_node rb_node;
    ext4_lblk_t es_lblk;    /* first logical block extent covers */
    ext4_lblk_t es_len;    /* length of extent in block */
    ext4_fsblk_t es_pblk;    /* first physical block */
};
```