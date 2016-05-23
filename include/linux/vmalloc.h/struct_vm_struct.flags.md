flags
========================================

VM_IOREMAP
----------------------------------------

path: include/linux/vmalloc.h
```
/* bits in flags of vmalloc's vm_struct below */
#define VM_IOREMAP       0x00000001    /* ioremap() and friends */
```

表示将几乎随机的物理内存区域映射到vmalloc区域中。这是一个特定于体系结构的操作。

VM_ALLOC
----------------------------------------

```
#define VM_ALLOC         0x00000002    /* vmalloc() */
```

指定由vmalloc产生的子区域。

VM_MAP
----------------------------------------

```
#define VM_MAP           0x00000004    /* vmap()ed pages */
```

用于表示将现存pages集合映射到连续的虚拟地址空间中。

```
#define VM_USERMAP       0x00000008    /* suitable for remap_vmalloc_range */
#define VM_VPAGES        0x00000010    /* buffer for pages was vmalloc'ed */
#define VM_UNINITIALIZED 0x00000020    /* vm_struct is not fully initialized */
#define VM_NO_GUARD      0x00000040    /* don't add guard page */
#define VM_KASAN         0x00000080    /* has allocated kasan shadow memory */
```