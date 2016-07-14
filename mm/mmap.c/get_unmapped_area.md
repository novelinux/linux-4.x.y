get_unmapped_area
========================================

get_unmapped_area函数，在虚拟地址空间中找到一个适当的区域用于映射。
我们知道，应用程序可以对映射指定固定地址、建议一个地址或由内核选择地址。
再向数据结构mm_struct插入新区域之前，内核必须确认进程虚拟地址
空间中有足够的空闲空间，可用于给定长度的区域.

Arguments
----------------------------------------

path: mm/mmap.c
```
unsigned long
get_unmapped_area(struct file *file, unsigned long addr, unsigned long len,
        unsigned long pgoff, unsigned long flags)
{
    unsigned long (*get_area)(struct file *, unsigned long,
                  unsigned long, unsigned long, unsigned long);
```

arch_mmap_check
----------------------------------------

```
    unsigned long error = arch_mmap_check(addr, len, flags);
    if (error)
        return error;

    /* Careful about overflows.. */
    if (len > TASK_SIZE)
        return -ENOMEM;
```

get_area
----------------------------------------

```
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
```

### ARM

对于新的进程空间布局是使用函数arch_get_unmapped_area_topdown函数来寻找空闲映射区域的:

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/mm/mmap.c/arch_get_unmapped_area_topdown.md

arch_rebalance_pgtables
----------------------------------------

```
    addr = arch_rebalance_pgtables(addr, len);
```

security_mmap_addr
----------------------------------------

```
    error = security_mmap_addr(addr);
    return error ? error : addr;
}

EXPORT_SYMBOL(get_unmapped_area);
```
