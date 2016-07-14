struct vm_unmapped_area_info
========================================

path: include/linux/mm.h
```
struct vm_unmapped_area_info {
#define VM_UNMAPPED_AREA_TOPDOWN 1
    unsigned long flags;
    unsigned long length;
    unsigned long low_limit;
    unsigned long high_limit;
    unsigned long align_mask;
    unsigned long align_offset;
};
```
