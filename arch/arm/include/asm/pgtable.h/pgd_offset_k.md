pgd_offset_k
========================================

pgd_offset_k宏将一个0-4G范围内的虚拟地址转换为内核进程主页表中的对应页表项所在的地址。
它首先根据pgd_index计算该虚拟地址对应的页表项在主页表中的索引值这里需要注意PGDIR_SHIFT的值为21，
而非20，所以它的偏移是取2M大小区块的索引，这是由于pgd_t的类型为两个长整形的元素。
然后根据索引值和内核进程中的init_mm.pgd取得页表项地址。

path: arch/arm/include/asm/pgtable.h
```
/* to find an entry in a page-table-directory */
#define pgd_index(addr)       ((addr) >> PGDIR_SHIFT)

#define pgd_offset(mm, addr)  ((mm)->pgd + pgd_index(addr))

/* to find an entry in a kernel page-table-directory */
#define pgd_offset_k(addr)    pgd_offset(&init_mm, addr)
```

对于pgd_offset_k宏的说明如下：

* init_mm.pgd类型为pgd_t类型,所以主页表总是以2个页表项为一组,它的大小为2*sizeof(unsigned long)=8.

* 虚拟地址首先右移21位，是为了取高11位作为2个页表项为一组这里数据类型的索引值，
  在计算(mm)->pgd + pgd_index(addr)时，是指针的相加，等价于
  (pgd_t *)((unsigned long)init_mm.pgd + 8 * ((addr) >> 21))。

* 由于每个页表项的大小为4，所以对应于单个页表项的大小，其索引值为
  8 * ((addr) >> 21) / 4 = 2 * ((addr)，地址则为8 * ((addr) >> 21)。
  右移21然后乘以2，相当于取高12位，并将最后位置0，再乘以4则到达了地址,
  相当于乘以8。这里取的总是偶数索引，也即create_mapping传递给alloc_init_pud的pgd参数
  永远指向偶数索引。如果需要取奇数索引的页表项怎么办呢？该值将在alloc_init_pud中通过
  (addr & SECTION_SIZE)对它进行修正。

* 主页表项的基地址init_mm.pgd加上索引值就是主页表项的地址。

init_mm
----------------------------------------

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/mm/init-mm.c/init_mm.md

PGDIR_SHIFT
----------------------------------------

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/arch/arm/include/asm/pgtable-2level.h/PMD_XXX.md