get_unmapped_area
========================================

再向数据结构mm_struct插入新区域之前，内核必须确认进程虚拟地址
空间中有足够的空闲空间，可用于给定长度的区域.
get_unmapped_area函数是一个与体系结构相关的函数,当对应体系结构
定义了HAVE_ARCH_UNMAPPED_AREA宏，那么执行如下函数:

path: mm/mmap.c
```
unsigned long
get_unmapped_area(struct file *file, unsigned long addr, unsigned long len,
        unsigned long pgoff, unsigned long flags)
{
    unsigned long (*get_area)(struct file *, unsigned long,
                  unsigned long, unsigned long, unsigned long);

    unsigned long error = arch_mmap_check(addr, len, flags);
    if (error)
        return error;

    /* Careful about overflows.. */
    if (len > TASK_SIZE)
        return -ENOMEM;

    get_area = current->mm->get_unmapped_area;
    if (file && file->f_op->get_unmapped_area)
        get_area = file->f_op->get_unmapped_area;
    addr = get_area(file, addr, len, pgoff, flags);
    if (IS_ERR_VALUE(addr))
        return addr;

    if (addr > TASK_SIZE - len)
        return -ENOMEM;
    if (addr & ~PAGE_MASK)
        return -EINVAL;

    addr = arch_rebalance_pgtables(addr, len);
    error = security_mmap_addr(addr);
    return error ? error : addr;
}
```

该函数主要根据进程虚拟地址空间的布局选择不同的映射函数.
选择进程虚拟地址空间的布局是在setup_new_exec函数中调用
arch_pick_mmap_layout来选择的，具体实现如下所示:

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/fs/exec_c/setup_new_exec.md

* 对于经典的进程空间布局是使用arch_get_unmapped_area函数来寻找空闲映射区域的:

arch_get_unmapped_area
----------------------------------------

* 对于新的进程空间布局是使用函数arch_get_unmapped_area_topdown函数来寻找空闲映射区域的:

arch_get_unmapped_area_topdown
----------------------------------------

该函数针对新的进程空间布局选择空间映射区域的,具体实现如下所示:

### arm

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/mm/mmap_c/arch_get_unmapped_area_topdown.md
