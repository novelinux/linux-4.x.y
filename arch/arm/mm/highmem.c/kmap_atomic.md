kmap_atomic
========================================

kmap函数不能用于中断处理程序，因为它可能进入睡眠状态。如果pkmap数组中没有空闲位置，
该函数会进入睡眠状态，直至情形有所改善。因此内核提供了一个备选的映射函数，其执行是原子的，
逻辑上称为kmap_atomic。该函数的一个主要优点是它比普通的kmap快速。但它不能用于可能进入睡眠的代码。
因此，它对于很快就需要一个临时页的简短代码，是非常理想的。

Arguments
----------------------------------------

path: mm/highmem.c
```
void *kmap_atomic(struct page *page)
{
    unsigned int idx;
    unsigned long vaddr;
    void *kmap;
    int type;

    preempt_disable();
    pagefault_disable();
    if (!PageHighMem(page))
        return page_address(page);

#ifdef CONFIG_DEBUG_HIGHMEM
    /*
     * There is no cache coherency issue when non VIVT, so force the
     * dedicated kmap usage for better debugging purposes in that case.
     */
    if (!cache_is_vivt())
        kmap = NULL;
    else
#endif
        kmap = kmap_high_get(page);
    if (kmap)
        return kmap;

    type = kmap_atomic_idx_push();

    idx = FIX_KMAP_BEGIN + type + KM_TYPE_NR * smp_processor_id();
    vaddr = __fix_to_virt(idx);
#ifdef CONFIG_DEBUG_HIGHMEM
    /*
     * With debugging enabled, kunmap_atomic forces that entry to 0.
     * Make sure it was indeed properly unmapped.
     */
    BUG_ON(!pte_none(get_fixmap_pte(vaddr)));
#endif
    /*
     * When debugging is off, kunmap_atomic leaves the previous mapping
     * in place, so the contained TLB flush ensures the TLB is updated
     * with the new mapping.
     */
    set_fixmap_pte(idx, mk_pte(page, kmap_prot));

    return (void *)vaddr;
}
EXPORT_SYMBOL(kmap_atomic);
```