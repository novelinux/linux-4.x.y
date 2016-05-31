map_new_virtual
========================================

Arguments
----------------------------------------

path: mm/highmem.c
```
static inline unsigned long map_new_virtual(struct page *page)
{
    unsigned long vaddr;
    int count;
    unsigned int last_pkmap_nr;
    unsigned int color = get_pkmap_color(page);
```

start
----------------------------------------

### scan pkmap_count

从最后使用的位置（保存在全局变量last_pkmap_nr中）开始，反向扫描pkmap_count数组，直至找到一个
空闲位置。如果没有空闲位置，该函数进入睡眠状态，直至内核的另一部分执行解除映射操作腾出空位。
在到达pkmap_count的最大索引值时，搜索从位置0开始。在这种情况下，还调用flush_all_zero_pkmaps函数
刷出CPU高速缓存

```
start:
    count = get_pkmap_entries_count(color);
    /* Find an empty entry */
    for (;;) {
        last_pkmap_nr = get_next_pkmap_nr(color);
        if (no_more_pkmaps(last_pkmap_nr, color)) {
            flush_all_zero_pkmaps();
            count = get_pkmap_entries_count(color);
        }
        if (!pkmap_count[last_pkmap_nr])
            break;    /* Found a usable entry */
        if (--count)
            continue;
```

### set_pte_at

修改内核的页表，将该页映射在指定位置。但尚未更新TLB. 新位置的使用计数器设置为1, 如上所述，
这意味着该页已分配但无法使用，因为TLB项未更新。

```
        /*
         * Sleep for somebody else to unmap their entries
         */
        {
            DECLARE_WAITQUEUE(wait, current);
            wait_queue_head_t *pkmap_map_wait =
                get_pkmap_wait_queue_head(color);

            __set_current_state(TASK_UNINTERRUPTIBLE);
            add_wait_queue(pkmap_map_wait, &wait);
            unlock_kmap();
            schedule();
            remove_wait_queue(pkmap_map_wait, &wait);
            lock_kmap();

            /* Somebody else might have mapped it while we slept */
            if (page_address(page))
                return (unsigned long)page_address(page);

            /* Re-start */
            goto start;
        }
    }
    vaddr = PKMAP_ADDR(last_pkmap_nr);
    set_pte_at(&init_mm, vaddr,
           &(pkmap_page_table[last_pkmap_nr]), mk_pte(page, kmap_prot));

    pkmap_count[last_pkmap_nr] = 1;
```

### set_page_address

set_page_address将该页添加到持久内核映射的数据结构,该函数返回新映射页的虚拟地址。

```
    set_page_address(page, (void *)vaddr);

    return vaddr;
}
```
