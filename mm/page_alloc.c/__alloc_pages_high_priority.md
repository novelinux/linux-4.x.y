__alloc_pages_high_priority
========================================

在忽略水印的情况下，get_page_from_freelist仍然失败了。在这种情况下，也会放弃搜索，报告错误消息。
但如果设置了__GFP_NOFAIL，内核会进入无限循环首先等待(通过wait_iff_congested)块设备层结束“占线”，
在回收页时可能出现这种情况。接下来再次尝试分配，直至成功。

path: mm/page_alloc.c
```
/*
 * This is called in the allocator slow-path if the allocation request is of
 * sufficient urgency to ignore watermarks and take other desperate measures
 */
static inline struct page *
__alloc_pages_high_priority(gfp_t gfp_mask, unsigned int order,
                const struct alloc_context *ac)
{
    struct page *page;

    do {
        page = get_page_from_freelist(gfp_mask, order,
                        ALLOC_NO_WATERMARKS, ac);

        if (!page && gfp_mask & __GFP_NOFAIL)
            wait_iff_congested(ac->preferred_zone, BLK_RW_ASYNC,
                                    HZ/50);
    } while (!page && (gfp_mask & __GFP_NOFAIL));

    return page;
}
```