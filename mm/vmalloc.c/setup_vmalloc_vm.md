setup_vmalloc_vm
========================================

path: mm/vmalloc.c
```
static void setup_vmalloc_vm(struct vm_struct *vm, struct vmap_area *va,
                  unsigned long flags, const void *caller)
{
    spin_lock(&vmap_area_lock);
    vm->flags = flags;
    vm->addr = (void *)va->va_start;
    vm->size = va->va_end - va->va_start;
    vm->caller = caller;
    va->vm = vm;
    va->flags |= VM_VM_AREA;
    spin_unlock(&vmap_area_lock);
}
```
