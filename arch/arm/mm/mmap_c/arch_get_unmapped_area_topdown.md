arch_get_unmapped_area_topdown
========================================

path: arch/arm/mm/mmap.c
```
unsigned long
arch_get_unmapped_area_topdown(struct file *filp, const unsigned long addr0,
               const unsigned long len, const unsigned long pgoff,
               const unsigned long flags)
{
     struct vm_area_struct *vma;
     struct mm_struct *mm = current->mm;
     unsigned long addr = addr0;
     int do_align = 0;
     int aliasing = cache_is_vipt_aliasing();
     struct vm_unmapped_area_info info;

     ...

     return addr;
}
```

该函数的具体实现如下所示:

1.检查是否设置固定地址
----------------------------------------

首先检查是否设置了MAX_FIXED标志，该标志表示映射将在固定地址
创建。倘若如此，内核只会确保该地址满足对齐要求(按页),而且
所要求的区间完全在可用地址空间内.

```
     ...
     /*
      * We only need to do colour alignment if either the I or D
      * caches alias.
      */
     if (aliasing)
          do_align = filp || (flags & MAP_SHARED);

     /* requested length too big for entire address space */
     if (len > TASK_SIZE)
          return -ENOMEM;

     if (flags & MAP_FIXED) {
          if (aliasing && flags & MAP_SHARED &&
              (addr - (pgoff << PAGE_SHIFT)) & (SHMLBA - 1))
               return -EINVAL;
          return addr;
     }
     ...
```

2.检查是否设值特定优先选用的地址
----------------------------------------

如果没有设置MAP_FIXED标志，接下来会检查是否指定了一个
特定的优先选用(与固定地址不同)地址，内核会检查该区域
是否与现存区域重叠。如果不重叠，则将该地址作为目标返回.

```
    ...
     /* requesting a specific address */
     if (addr) {
          if (do_align)
               addr = COLOUR_ALIGN(addr, pgoff);
          else
               addr = PAGE_ALIGN(addr);
          vma = find_vma(mm, addr);
          if (TASK_SIZE - len >= addr &&
                    (!vma || addr + len <= vma->vm_start))
               return addr;
     }
     ...
```

### find_vma

find_vma用于在进程虚拟地址空间中查找结束地址在给定地址之后的
第一个区域. 即满足addr < vm_area_struct->vm_end条件的第一个区域.
该函数的参数不仅包括虚拟地址(addr),还包括一个指向mm_struct实例
的指针，后者指定了扫描哪个进程的地址空间.

具体实现如下所示:

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/mm/mmap_c/find_vma.md

3.vm_unmapped_area
----------------------------------------

如果进程没有设定固定地址和优先地址,那么内核必须遍历进程中可用区域，
设法找到一个大小适当的空闲区域。

```
     ...
     info.flags = VM_UNMAPPED_AREA_TOPDOWN;
     info.length = len;
     /* FIRST_USER_ADDRESS通常设置为PAGE_SIZE. */
     info.low_limit = FIRST_USER_ADDRESS;
     info.high_limit = mm->mmap_base;
     info.align_mask = do_align ? (PAGE_MASK & (SHMLBA - 1)) : 0;
     info.align_offset = pgoff << PAGE_SHIFT;
     addr = vm_unmapped_area(&info);

     /*
      * A failed mmap() very likely causes application failure,
      * so fall back to the bottom-up function here. This scenario
      * can happen with large stack limits and large mmap()
      * allocations.
      */
     if (addr & ~PAGE_MASK) {
          VM_BUG_ON(addr != -ENOMEM);
          info.flags = 0;
          info.low_limit = mm->mmap_base;
          info.high_limit = TASK_SIZE;
          addr = vm_unmapped_area(&info);
     }
     ...
```

### vm_unmapped_area

path: include/linux/mm.h
```
/*
 * Search for an unmapped address range.
 *
 * We are looking for a range that:
 * - does not intersect with any VMA;
 * - is contained within the [low_limit, high_limit) interval;
 * - is at least the desired size.
 * - satisfies (begin_addr & align_mask) == (align_offset & align_mask)
 */
static inline unsigned long
vm_unmapped_area(struct vm_unmapped_area_info *info)
{
    if (!(info->flags & VM_UNMAPPED_AREA_TOPDOWN))
        return unmapped_area(info);
    else
        return unmapped_area_topdown(info);
}
```

unmapped_area_topdown的具体实现如下所示:

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/mm/mmap_c/unmapped_area_topdown.md
