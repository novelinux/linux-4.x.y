__insert_vmap_area
========================================

path: mm/vmalloc.c
```
static void __insert_vmap_area(struct vmap_area *va)
{
    struct rb_node **p = &vmap_area_root.rb_node;
    struct rb_node *parent = NULL;
    struct rb_node *tmp;

    while (*p) {
        struct vmap_area *tmp_va;

        parent = *p;
        tmp_va = rb_entry(parent, struct vmap_area, rb_node);
        if (va->va_start < tmp_va->va_end)
            p = &(*p)->rb_left;
        else if (va->va_end > tmp_va->va_start)
            p = &(*p)->rb_right;
        else
            BUG();
    }

    rb_link_node(&va->rb_node, parent, p);
    rb_insert_color(&va->rb_node, &vmap_area_root);

    /* address-sort this list */
    tmp = rb_prev(&va->rb_node);
    if (tmp) {
        struct vmap_area *prev;
        prev = rb_entry(tmp, struct vmap_area, rb_node);
        list_add_rcu(&va->list, &prev->list);
    } else
        list_add_rcu(&va->list, &vmap_area_list);
}
```
