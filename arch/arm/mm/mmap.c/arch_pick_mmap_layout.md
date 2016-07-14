arch_pick_mmap_layout
========================================

Arguments
----------------------------------------

path: arch/arm/mm/mmap.c
```
void arch_pick_mmap_layout(struct mm_struct *mm)
{
```

arch_mmap_rnd
----------------------------------------

如果当前进程的flags设置了PF_RANDOMIZE标志并且personality没有设置过
ADDR_NO_RANDOMIZE标志, 那么说明不会设置当前进程内存映射的起点为固定位置，
于是计算一个随机值保存到

```
    unsigned long random_factor = 0UL;

    if (current->flags & PF_RANDOMIZE)
        random_factor = arch_mmap_rnd();
```

https://github.com/novelinux/linux-4.x.y/blob/master/arch/arm/mm/mmap.c/arch_mmap_rnd.md

mmap_is_legacy
----------------------------------------

```
    if (mmap_is_legacy()) {
        mm->mmap_base = TASK_UNMAPPED_BASE + random_factor;
        mm->get_unmapped_area = arch_get_unmapped_area;
    } else {
        mm->mmap_base = mmap_base(random_factor);
        mm->get_unmapped_area = arch_get_unmapped_area_topdown;
    }
}
```

https://github.com/novelinux/linux-4.x.y/blob/master/arch/arm/mm/mmap.c/mmap_is_legacy.md

### old layout

mmap_is_legacy等于1表示使用经典布局:

在经典的配置下，mmap区域的起始点是TASK_UNMAPPED_BASE, 其值位于
TASK_SIZE / 3处，大约在0x40000000（1GB）处, 而标准函数
arch_get_unmapped_area(其名称虽然带着arch, 但该函数不一定是特定于
体系结构的，内核也提供了一个标准实现)用于自下而上的创建新的映射.

#### TASK_UNMAPPED_BASE

https://github.com/novelinux/linux-4.x.y/blob/master/arch/arm/include/asm/memory.h/TASK_UNMAPPED_BASE.md

#### arch_get_unmapped_area

https://github.com/novelinux/linux-4.x.y/blob/master/arch/arm/mm/mmap.c/arch_get_unmapped_area.md

### new layout

mmap_is_legacy等于0表示使用新的布局:

在使用新的布局时，内存映射自顶向下增长。标准函数arch_get_unmapped_area_topdown.
内存映射基地址的选择是由函数mmap_base来决定的，具体实现如下所示:

#### mmap_base

https://github.com/novelinux/linux-4.x.y/blob/master/arch/arm/mm/mmap.c/mmap_base.md

#### arch_get_unmapped_area_topdown

https://github.com/novelinux/linux-4.x.y/blob/master/arch/arm/mm/mmap.c/arch_get_unmapped_area_topdown.md
