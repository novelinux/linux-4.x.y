arch_pick_mmap_layout
========================================

Source
----------------------------------------

path: arch/arm/mm/mmap.c
```
void arch_pick_mmap_layout(struct mm_struct *mm)
{
    unsigned long random_factor = 0UL;

    /* 8 bits of randomness in 20 address space bits */
    /* 1. 如果当前进程的flags设置了PF_RANDOMIZE标志并且personality没有设置过ADDR_NO_RANDOMIZE
     * 标志, 那么说明不会设置当前进程内存映射的起点为固定位置，于是计算一个随机值保存到
     * random_factor中.
     */
    if ((current->flags & PF_RANDOMIZE) &&
        !(current->personality & ADDR_NO_RANDOMIZE))
        random_factor = (get_random_int() % (1 << 8)) << PAGE_SHIFT;

    if (mmap_is_legacy()) {
        mm->mmap_base = TASK_UNMAPPED_BASE + random_factor;
        mm->get_unmapped_area = arch_get_unmapped_area;
    } else {
        mm->mmap_base = mmap_base(random_factor);
        mm->get_unmapped_area = arch_get_unmapped_area_topdown;
    }
}
```

1.检查当前进程是否需要设置内存映射的起点为固定位置
----------------------------------------

2.mmap_is_legacy
----------------------------------------

path: arch/arm/mm/mmap.c
```
static int mmap_is_legacy(void)
{
    if (current->personality & ADDR_COMPAT_LAYOUT)
        return 1;

    if (rlimit(RLIMIT_STACK) == RLIM_INFINITY)
        return 1;

    return sysctl_legacy_va_layout;
}
```

如果用户通过/proc/sys/kernel/legacy_va_layout给出明确的指示，或者要执行行为不同的UNIX变体编译,
需要为二进制文件创建旧的进程空间布局, 或者栈可以无线增长，则系统会选择旧的布局。这使得很难确定
栈的下界，亦或者是mmap区域的上界:

3.决定使用何种进程空间布局
----------------------------------------

### mmap_is_legacy等于1表示使用经典布局

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/mm/res/old_vpm_layout.png

在经典的配置下，mmap区域的起始点是TASK_UNMAPPED_BASE, 其值位于TASK_SIZE / 3处，大约在
0x40000000（1GB）处, 而标准函数arch_get_unmapped_area(其名称虽然带着arch, 但该函数不一定
是特定于体系结构的，内核也提供了一个标准实现)用于自下而上的创建新的映射.

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/arch/arm/include/asm/memory_h/memory.md

### mmap_is_legacy等于0表示使用新的布局

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/mm/res/new_vpm_layout.png

在使用新的布局时，内存映射自顶向下增长。标准函数arch_get_unmapped_area_topdown.
内存映射基地址的选择是由函数mmap_base来决定的，具体实现如下所示:

path: arch/arm/mm/mmap.c
```
/* gap between mmap and stack */
#define MIN_GAP (128*1024*1024UL)
#define MAX_GAP ((TASK_SIZE)/6*5)
...
static unsigned long mmap_base(unsigned long rnd)
{
    unsigned long gap = rlimit(RLIMIT_STACK);

    if (gap < MIN_GAP)
        gap = MIN_GAP;
    else if (gap > MAX_GAP)
        gap = MAX_GAP;

    return PAGE_ALIGN(TASK_SIZE - gap - rnd);
}
```

可以根据栈的最大长度，来计算栈最低的可能位置，用作mmap区域的起始点，但内核会确保栈
至少跨越128MB的空间。另外，如果指定的栈界限非常巨大，那么内核会至少保证有一小部分地址
空间不被占据。
如果要求使用地址空间随机化机制，上述位置会减去一个随机的偏移量值，最大为1MB.
另外，内核会确保该区域会对齐到页帧，这是体系结构的要求.
