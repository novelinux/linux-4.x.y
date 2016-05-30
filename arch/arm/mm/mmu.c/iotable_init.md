iotable_init
========================================

path: arch/arm/mm/mmu.c
```
/*
 * Create the architecture specific mappings
 */
void __init iotable_init(struct map_desc *io_desc, int nr)
{
    struct map_desc *md;
    struct vm_struct *vm;
    struct static_vm *svm;

    if (!nr)
        return;

    svm = early_alloc_aligned(sizeof(*svm) * nr, __alignof__(*svm));

    for (md = io_desc; nr; md++, nr--) {
        create_mapping(md);

        vm = &svm->vm;
        vm->addr = (void *)(md->virtual & PAGE_MASK);
        vm->size = PAGE_ALIGN(md->length + (md->virtual & ~PAGE_MASK));
        vm->phys_addr = __pfn_to_phys(md->pfn);
        vm->flags = VM_IOREMAP | VM_ARM_STATIC_MAPPING;
        vm->flags |= VM_ARM_MTYPE(md->type);
        vm->caller = iotable_init;
        add_static_vm_early(svm++);
    }
}
```
