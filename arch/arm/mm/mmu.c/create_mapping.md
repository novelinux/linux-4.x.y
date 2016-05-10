create_mapping
========================================

struct map_desc
----------------------------------------

create_mapping只有一个类型为struct map_desc的参数。这是一个非常简单的参数，但是包含了创建页表
相关的所有信息。

path: arch/arm/mm/mmu.c
```
/*
 * Create the page directory entries and any necessary
 * page tables for the mapping specified by `md'.  We
 * are able to cope here with varying sizes and address
 * offsets, and we take full advantage of sections and
 * supersections.
 */
static void __init create_mapping(struct map_desc *md)
{
```

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/include/asm/mach/map.h/struct_map_desc.md

参数合法性检查
----------------------------------------

```
    unsigned long addr, length, end;
    phys_addr_t phys;
    const struct mem_type *type;
    pgd_t *pgd;

    /* 首先根据传入的virtual虚拟地址与中断向量起始地址比较，除特殊的
     * 中断向量使用的虚拟地址可能落在0地址外，确保映射到的虚拟地址落在内核空间。
     *
     * 通过vectors_base宏，获取中断向量的起始地址，这是由于ARMv4以下的版本，该地址固定为0;
     * ARMv4及以上版本，ARM中断向量表的地址由CP15协处理器c1寄存器中的V位(bit[13])控制，
     * 如果V位为1，那么该地址为0xffff0000。考虑到除了ARMv4以下的版本的
     * 中断向量所在的虚拟地址为0，其他所有映射到的虚拟地址应该都在地址
     * 0xc0000000之上的内核空间，而不可能被映射到用户空间。
     */
    if (md->virtual != vectors_base() && md->virtual < TASK_SIZE) {
        pr_warn("BUG: not creating mapping for 0x%08llx at 0x%08lx in user region\n",
            (long long)__pfn_to_phys((u64)md->pfn), md->virtual);
        return;
    }
```

### TASK_SIZE

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/arch/arm/include/asm/memory.h/TASK_SIZE.md

mem_types
----------------------------------------

```
    /*接着根据type类型判断是否为普通设备或者ROM，这些设备中的内存不能被映射到RAM映射的
     * 区域[PAGE_OFFSET，high_memory)，也不能被映射到VMALLOC所在的区域[high_memory，VMALLOC_END)，
     * 由于这两个区域是连续的，中间隔了8M的VMALLOC_OFFSET隔离区，准确来说是不能映射到
     * [VMALLOC_START，VMALLOC_END)，但是这一隔离区为了使能隔离之用也是不能被映射的。
     */
    if ((md->type == MT_DEVICE || md->type == MT_ROM) &&
        md->virtual >= PAGE_OFFSET &&
        (md->virtual < VMALLOC_START || md->virtual >= VMALLOC_END)) {
        pr_warn("BUG: mapping for 0x%08llx at 0x%08lx out of vmalloc space\n",
            (long long)__pfn_to_phys((u64)md->pfn), md->virtual);
    }

    type = &mem_types[md->type];

#ifndef CONFIG_ARM_LPAE
    /*
     * Catch 36-bit addresses
     */
    /* 根据pfn与1G内存对应的最大物理页框0x100000比较，如果物理内存的起始地址位于32bits
     * 的物理地址之外，那么通过create_36bit_mapping创建36bits长度的页表，
     * 对于嵌入式系统来说很少有这种应用
     */
    if (md->pfn >= 0x100000) {
        create_36bit_mapping(md, type);
        return;
    }
#endif
    ...
```

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/mm/mmu.c/mem_types.md

pgd
----------------------------------------

页全局目录(Page Global Directory)，即 pgd，是多级页表的抽象最高层。每一级的页表都处理不同大小的
内存。每项都指向一个更小目录的低级表，因此pgd就是一个页表目录。当代码遍历这个结构时
（有些驱动程序就要这样做），就称为是在遍历页表。

获得该虚拟地址addr属于第一级页表(L1)的哪个表项，详细跟踪pgd_offset_k函数，我们内核的L1
页目录表的基地址位于0xc0004000，而我们的内核代码则是放置在0xc0008000开始的位置。
而从0xc0004000到0xc0008000区间大小是16KB，刚好就是L1页表的大小

在这里需要注意一个概念: 内核的页目录表项和进程的页目录表项，内核的页目录表项是对系统所有进程
都是公共的；而进程的页目录表项则是跟特定进程相关的，每个应用进程都有自己的页目录表项，但
各个进程对应的内核空间的页目录表相都是一样的。正是由于每个进程都有自己的页目录表相，所以
才能做到每个进程都可以独立拥有属于自己的[0，3GB]的内存空间。

```
    /* 调整传入的md中的各成员信息:
     * 1.virtual向低地址对齐到页面大小;
     * 2.根据length参数取对齐到页面的大小的长度，并以此计算映射结束的虚拟地址。
     * 3.根据pfn参数计算起始物理地址。
     */
    addr = md->virtual & PAGE_MASK;
    phys = __pfn_to_phys(md->pfn);
    length = PAGE_ALIGN(md->length + (md->virtual & ~PAGE_MASK));

    if (type->prot_l1 == 0 && ((addr | phys | length) & ~SECTION_MASK)) {
        pr_warn("BUG: map for 0x%08llx at 0x%08lx can not be mapped using pages, ignoring.\n",
            (long long)__pfn_to_phys(md->pfn), addr);
        return;
    }

    // 一级数组中addr对应的段在init_mm->pgd(0xc0004000)的下标
    // 根据虚拟地址和公式pgd = pgd_offset_k(addr)计算页表地址。
    pgd = pgd_offset_k(addr);
```

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/arch/arm/include/asm/pgtable.h/pgd_offset_k.md


alloc_init_pud
----------------------------------------

alloc_init_pud()函数为定位到的L1页目录表项pgd所指向的二级页表(L2)建立映射表

```
    printk(KERN_CRIT "liminghao: %s(%lx: %lx~%lx) - %lx - pgd(%p)\n",
           __FUNCTION__, (unsigned long)phys, addr, end, length,
           (void *)(pgd));
    // 计算结束地址
    end = addr + length;
    do {
        // 获得下一页开始地址
        // pgd_addr_end()确保[addr，next]地址不会跨越一个L1表项所能映射的最大内存空间2MB
        unsigned long next = pgd_addr_end(addr, end);

        printk(KERN_CRIT "liminghao: %s(%lx: %lx~%lx) - pgd(%p)\n",
               __FUNCTION__, (unsigned long)phys, addr, next,
               (void *)(pgd));

        alloc_init_pud(pgd, addr, next, phys, type);

        phys += next - addr;
        addr = next;

        // pdg++下移L1页目录表项pgd，映射下一个2MB空间的虚拟地址到对应的2MB的物理空间。
    } while (pgd++, addr != end);
}
```

### pgd_addr_end

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/include/asm-generic/pgtable.h/pgd_addr_end.md

### demsg

```
[    0.000000] liminghao: map_lowmem(80200000~88e00000)
[    0.000000] liminghao: map_lowmem(c0000000~c8c00000)
```

以如上memory region的映射我们看下相关的映射过程:

```
[    0.000000] liminghao: create_mapping(80200000: c0000000~c0100000) - 100000 - pgd(c0007000)
[    0.000000] liminghao: create_mapping(80200000: c0000000~c0100000) - pgd(c0007000)

[    0.000000] liminghao: create_mapping(80300000: c0100000~c0a00000) - 900000 - pgd(c0007000)
[    0.000000] liminghao: create_mapping(80300000: c0100000~c0200000) - pgd(c0007000)
[    0.000000] liminghao: create_mapping(80400000: c0200000~c0400000) - pgd(c0007008)
[    0.000000] liminghao: create_mapping(80600000: c0400000~c0600000) - pgd(c0007010)
[    0.000000] liminghao: create_mapping(80800000: c0600000~c0800000) - pgd(c0007018)
[    0.000000] liminghao: create_mapping(80a00000: c0800000~c0a00000) - pgd(c0007020)

[    0.000000] liminghao: create_mapping(80c00000: c0a00000~c0f00000) - 500000 - pgd(c0007028)
[    0.000000] liminghao: create_mapping(80c00000: c0a00000~c0c00000) - pgd(c0007028)
[    0.000000] liminghao: create_mapping(80e00000: c0c00000~c0e00000) - pgd(c0007030)
[    0.000000] liminghao: create_mapping(81000000: c0e00000~c0f00000) - pgd(c0007038)

[    0.000000] liminghao: create_mapping(81100000: c0f00000~c1000000) - 100000 - pgd(c0007038)
[    0.000000] liminghao: create_mapping(81100000: c0f00000~c1000000) - pgd(c0007038)

[    0.000000] liminghao: create_mapping(81200000: c1000000~c8c00000) - 7c00000 - pgd(c0007040)
[    0.000000] liminghao: create_mapping(81200000: c1000000~c1200000) - pgd(c0007040)
[    0.000000] liminghao: create_mapping(81400000: c1200000~c1400000) - pgd(c0007048)
...
[    0.000000] liminghao: create_mapping(88800000: c8600000~c8800000) - pgd(c0007218)
[    0.000000] liminghao: create_mapping(88a00000: c8800000~c8a00000) - pgd(c0007220)
[    0.000000] liminghao: create_mapping(88c00000: c8a00000~c8c00000) - pgd(c0007228)
...
```

从如上dmesg中我们得知在这块区间物理地址和虚拟地址是一一映射的,例如:

```
(0x80200000 ~ 0x80300000) --> (0xc0000000 ~ 0xc0100000)
```
其中pgd正是一级页表0xc0004000~0xc0008000之间的偏移量.

### alloc_init_pud

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/mm/mmu.c/alloc_init_pud.md

问题
----------------------------------------

L1表项所能映射为什么是2MB而不是1MB呢? 这个是linux的一个处理技巧.
arm典型的mmu映射框架图显示的是映射1MB, linux映射框架图在它的基础做了些调整和优化。
linux所做的调整描述如下:

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/arch/arm/include/asm/pgtable-2level.h/README.md
