kmap_high
========================================

page_address函数首先检查该页是否已经映射。如果它不对应到有效地址，则必须使用map_new_virtual
映射该页。

path: mm/highmem.c
```
/**
 * kmap_high - map a highmem page into memory
 * @page: &struct page to map
 *
 * Returns the page's virtual memory address.
 *
 * We cannot call this from interrupts, as it may block.
 */
void *kmap_high(struct page *page)
{
    unsigned long vaddr;
```

page_address
----------------------------------------

```
    /*
     * For highmem pages, we can't trust "virtual" until
     * after we have the lock.
     */
    lock_kmap();
    vaddr = (unsigned long)page_address(page);
```

map_new_virtual
----------------------------------------

```
    if (!vaddr)
        vaddr = map_new_virtual(page);
    pkmap_count[PKMAP_NR(vaddr)]++;
    BUG_ON(pkmap_count[PKMAP_NR(vaddr)] < 2);
    unlock_kmap();
    return (void*) vaddr;
}
```

https://github.com/novelinux/linux-4.x.y/blob/master/mm/highmem.c/map_new_virtual.md
