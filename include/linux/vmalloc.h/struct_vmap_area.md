struct vmap_area
========================================

path: include/linux/vmalloc.h
```
struct vmap_area {
    unsigned long va_start;
    unsigned long va_end;
    unsigned long flags;
    struct rb_node rb_node;         /* address sorted rbtree */
    struct list_head list;          /* address sorted list */
    struct list_head purge_list;    /* "lazy purge" list */
    struct vm_struct *vm;
    struct rcu_head rcu_head;
};
```