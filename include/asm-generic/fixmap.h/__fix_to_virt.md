__fix_to_virt
========================================

path: include/asm-generic/fixmap.h
```
#define __fix_to_virt(x)    (FIXADDR_TOP - ((x) << PAGE_SHIFT))
#define __virt_to_fix(x)    ((FIXADDR_TOP - ((x)&PAGE_MASK)) >> PAGE_SHIFT)

#ifndef __ASSEMBLY__
/*
 * 'index to address' translation. If anyone tries to use the idx
 * directly without translation, we catch the bug with a NULL-deference
 * kernel oops. Illegal ranges of incoming indices are caught too.
 */
static __always_inline unsigned long fix_to_virt(const unsigned int idx)
{
    BUILD_BUG_ON(idx >= __end_of_fixed_addresses);
    return __fix_to_virt(idx);
}

static inline unsigned long virt_to_fix(const unsigned long vaddr)
{
    BUG_ON(vaddr >= FIXADDR_TOP || vaddr < FIXADDR_START);
    return __virt_to_fix(vaddr);
}
...
#endif
```

fix_to_virt
----------------------------------------

编译器优化机制会完全消除条件语句，因为该函数定义为内联函数，而且其参数都是常数。这样的优化是
有必要的，否则固定映射地址实际上并不优于普通指针。形式上的检查确保了所需的固定映射地址在
有效区域中。__end_of_fixed_adresses是fixed_addresses的最后一个成员，定义了最大的可能数字。
如果内核访问的是无效地址，则调用伪函数__this_fixmap_does_not_exist（没有定义）。在内核链接时，
这会导致错误信息，表明由于存在未定义符号而无法生成映像文件。因此，此种内核故障在编译时即可检测，
而不会在运行时出现。在引用有效的固定映射地址时，条件语句中的比较总是会通过。由于比较的两个操作数
都是常数，该条件判断语句实际上不会执行，在编译优化的过程中会直接消除。

__fix_to_virt
----------------------------------------

__fix_to_virt定义为宏。由于fix_to_virt是内联函数，其实现代码会直接复制到查询固定映射地址的代码处。

从顶部开始（不是按照常理从底部开始），内核回退n页，以确定第n个固定映射项的虚拟地址。这个计算同样
也只使用了常数，编译器能够在编译时计算结果。根据上文提到的内存划分，地址空间中对应的虚拟地址尚未
用于其他用途。

固定映射虚拟地址与物理内存页之间的关联是由set_fixmap(fixmap, page_nr)和set_fixmap_nocache建立的。
这两个函数只是将页表中的对应项与物理内存中的一页关联起来。不同于set_fixmap，set_fixmap_nocache
在必要情况下，会停用所涉及页帧的硬件高速缓存。
