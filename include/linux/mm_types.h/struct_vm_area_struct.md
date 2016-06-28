struct vm_area_struct
========================================

vm_start, vm_end
----------------------------------------

path: include/linux/mm_types.h
```
/*
 * This struct defines a memory VMM memory area. There is one of these
 * per VM-area/task.  A VM area is any part of the process virtual memory
 * space that has a special rule for the page-fault handlers (ie a shared
 * library, the executable area etc).
 */
struct vm_area_struct {
    /* The first cache line has the info for VMA tree walking. */

    unsigned long vm_start;        /* Our start address within vm_mm. */
    unsigned long vm_end;        /* The first byte after our end address
                       within vm_mm. */
```

指定了改区域在用户空间中的起始和结束地址.

vm_next, vm_prev, vm_rb
----------------------------------------

```
    /* linked list of VM areas per task, sorted by address */
    struct vm_area_struct *vm_next, *vm_prev;

    struct rb_node vm_rb;
```

进程所有vm_area_struct实例的链表是通过vm_next和vm_prev实现的，
而与红黑树的集成则是通过vm_rb来实现的.

rb_subtree_gap
----------------------------------------

```
    /*
     * Largest free memory gap in bytes to the left of this VMA.
     * Either between this VMA and vma->vm_prev, or between one of the
     * VMAs below us in the VMA rbtree and its ->vm_prev. This helps
     * get_unmapped_area find a free area of the right size.
     */
    unsigned long rb_subtree_gap;
```

vm_mm
----------------------------------------

```
    /* Second cache line starts here. */

    struct mm_struct *vm_mm;    /* The address space we belong to. */
```

vm_mm是一个反向指针，指向改区域所属的mm_struct实例

vm_page_prot
----------------------------------------


```
    pgprot_t vm_page_prot;        /* Access permissions of this VMA. */
```

存储该区域的访问权限.

vm_flags
----------------------------------------

```
    unsigned long vm_flags;        /* Flags, see mm.h. */
```

描述该区域的一组标志. 这些常用标志定义如下所示:

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/mm.h/struct_vm_area_struct.vm_flags.md

shared
----------------------------------------

```
    /*
     * For areas with an address space and backing store,
     * linkage into the address_space->i_mmap interval tree, or
     * linkage of vma in the address_space->i_mmap_nonlinear list.
     */
    union {
        struct {
            struct rb_node rb;
            unsigned long rb_subtree_last;
        } linear;
        struct list_head nonlinear;
    } shared;
```

从文件到进程的虚拟地址空间中的映射，可以通过文件中的区间和内存中对应的区间
唯一地确定。为跟踪与进程关联的所有区间，内核使用了如上所述的链表和红黑树.
但还必须能够反向查询：给出文件的一个区间，内核有时需要知道改区间映射到的
所有进程，这种映射被称为共享映射，至于这种映射的必要性，看看系统中几乎每个
进程都使用的c标准库.为了提供所需的信息，所有的vm_area_struct实例都还通过
一个优先树管理，包含在shared成员中.

anon_vma_chain, anon_vma
----------------------------------------

```
    /*
     * A file's MAP_PRIVATE vma can be in both i_mmap tree and anon_vma
     * list, after a COW of one of the file pages.    A MAP_SHARED vma
     * can only be in the i_mmap tree.  An anonymous MAP_PRIVATE, stack
     * or brk vma (with NULL file) can only be in an anon_vma list.
     */
    struct list_head anon_vma_chain; /* Serialized by mmap_sem &
                      * page_table_lock */
    struct anon_vma *anon_vma;    /* Serialized by page_table_lock */
```

用于管理源自匿名映射的共享页。指向相同页的映射都保存在一个双链表上，
anon_vma_chain充当链表元素。有若干此类链表，具体的数目取决于贡献物理内存
页的映射集合的数目。anon_vma成员是一个指向与各链表关联的管理结构的指针，
改管理结构由一个表头和相关的锁组成.

vm_ops
----------------------------------------

```
    /* Function pointers to deal with this struct. */
    const struct vm_operations_struct *vm_ops;
```

是一个指针，指向许多方法的集合，这些方法用于在区域上执行各种标准操作.

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/mm.h/struct_vm_operations_struct.md

vm_pgoff
----------------------------------------

```
    /* Information about our backing store: */
    unsigned long vm_pgoff;        /* Offset (within vm_file) in PAGE_SIZE
                       units, *not* PAGE_CACHE_SIZE */
```

指定了文件映射的偏移量，该值用于只映射了文件部分内容时（如果映射了整个
文件，则偏移量为0）。偏移量的单位不是字节，而是页(PAGE_SIZE).

vm_file
----------------------------------------

```
    struct file * vm_file;        /* File we map to (can be NULL). */
```

vm_file指向了file实例，描述了一个被映射的文件。如果映射的对象不是文件则是NULL指针.

vm_private_data
----------------------------------------

```
    void * vm_private_data;        /* was vm_pte (shared mem) */
```

可用于存储私有数据，不由通用的内存管理例程操作。内核只确保在创建新区域时
该成员初始化为NULL指针。当前，binder驱动会使用改选项.

vm_region
----------------------------------------

```
#ifndef CONFIG_MMU
    struct vm_region *vm_region;    /* NOMMU mapping region */
#endif
#ifdef CONFIG_NUMA
    struct mempolicy *vm_policy;    /* NUMA policy for the VMA */
#endif
};
```
