kunmap
========================================

用kmap映射的页，如果不再需要，必须用kunmap解除映射。照例，该函数首先检查相关的页（由page实例标识）
是否确实在高端内存中。倘若如此，则实际工作委托给kunmap_high，该函数的主要任务是将pkmap_count数组中
对应位置在计数器减1.

**注意**: 该机制永远不能将计数器值降低到小于1。这意味着相关的页没有释放。因为对使用计数器进行了
额外的加1操作，正如前文的讨论，这是为确保CPU高速缓存的正确处理。

path: arch/arm/mm/highmem.c
```
void kunmap(struct page *page)
{
    BUG_ON(in_interrupt());
    if (!PageHighMem(page))
        return;
    kunmap_high(page);
}
```

kunmap_high
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/highmem.c/kunmap_high.md
