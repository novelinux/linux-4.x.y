vmalloc_init
========================================

Arguments
---------------------------------------

path: mm/vmalloc.c
```
void __init vmalloc_init(void)
{
    struct vmap_area *va;
    struct vm_struct *tmp;
    int i;

    for_each_possible_cpu(i) {
        struct vmap_block_queue *vbq;
        struct vfree_deferred *p;

        vbq = &per_cpu(vmap_block_queue, i);
        spin_lock_init(&vbq->lock);
        INIT_LIST_HEAD(&vbq->free);
        p = &per_cpu(vfree_deferred, i);
        init_llist_head(&p->list);
        INIT_WORK(&p->wq, free_work);
    }
```

__insert_vmap_area
----------------------------------------

遍历vmlist逐个取出vm_struct实例初始化vmap_area,插入到对应的数据结构中去.

```
    /* Import existing vmlist entries. */
    for (tmp = vmlist; tmp; tmp = tmp->next) {
        va = kzalloc(sizeof(struct vmap_area), GFP_NOWAIT);
        va->flags = VM_VM_AREA;
        va->va_start = (unsigned long)tmp->addr;
        va->va_end = va->va_start + tmp->size;
        va->vm = tmp;
        __insert_vmap_area(va);
    }

    vmap_area_pcpu_hole = VMALLOC_END;

    vmap_initialized = true;
}
```

### vmlist

https://github.com/novelinux/linux-4.x.y/tree/master/mm/vmalloc.c/vmlist.md

### __insert_vmap_area

https://github.com/novelinux/linux-4.x.y/tree/master/mm/vmalloc.c/__insert_vmap_area.md
