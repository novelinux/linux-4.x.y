vm_area_add_early
========================================

path: mm/vmalloc.c
```
/**
 * vm_area_add_early - add vmap area early during boot
 * @vm: vm_struct to add
 *
 * This function is used to add fixed kernel vm area to vmlist before
 * vmalloc_init() is called.  @vm->addr, @vm->size, and @vm->flags
 * should contain proper values and the other fields should be zero.
 *
 * DO NOT USE THIS FUNCTION UNLESS YOU KNOW WHAT YOU'RE DOING.
 */
void __init vm_area_add_early(struct vm_struct *vm)
{
    struct vm_struct *tmp, **p;

    BUG_ON(vmap_initialized);
    for (p = &vmlist; (tmp = *p) != NULL; p = &tmp->next) {
        if (tmp->addr >= vm->addr) {
            BUG_ON(tmp->addr < vm->addr + vm->size);
            break;
        } else
            BUG_ON(tmp->addr + tmp->size > vm->addr);
    }
    vm->next = *p;
    *p = vm;
}
```
