kmap
========================================

Arguements
----------------------------------------

path: arch/arm/mm/highmem.c
```
void *kmap(struct page *page)
{
    might_sleep();
```

page_address
----------------------------------------

```
    if (!PageHighMem(page))
        return page_address(page);
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/highmem.c/page_address.md

kmap_high
----------------------------------------

```
    return kmap_high(page);
}
EXPORT_SYMBOL(kmap);
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/highmem.c/kmap_high.md