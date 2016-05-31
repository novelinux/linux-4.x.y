page_address
========================================

page_address是一个前端函数，使用相应的数据结构确定给定page实例的地址.

page_address首先检查传递进来的page实例在普通内存还是在高端内存。如果是前者，页地址可以根据
page在mem_map数组中的位置计算。对于后者，可通过上述散列表page_address_htable查找虚拟地址。

Arguments
----------------------------------------

path: mm/highmem.c
```
/**
 * page_address - get the mapped virtual address of a page
 * @page: &struct page to get the virtual address of
 *
 * Returns the page's virtual address.
 */
void *page_address(const struct page *page)
{
    unsigned long flags;
    void *ret;
    struct page_address_slot *pas;

    if (!PageHighMem(page))
        return lowmem_page_address(page);

    pas = page_slot(page);
    ret = NULL;
    spin_lock_irqsave(&pas->lock, flags);
    if (!list_empty(&pas->lh)) {
        struct page_address_map *pam;

        list_for_each_entry(pam, &pas->lh, list) {
            if (pam->page == page) {
                ret = pam->virtual;
                goto done;
            }
        }
    }
done:
    spin_unlock_irqrestore(&pas->lock, flags);
    return ret;
}
```