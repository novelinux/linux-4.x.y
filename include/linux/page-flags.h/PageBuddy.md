PageBuddy
========================================

path: include/linux/page-flags.h
```
/*
 * PageBuddy() indicate that the page is free and in the buddy system
 * (see mm/page_alloc.c).
 *
 * PAGE_BUDDY_MAPCOUNT_VALUE must be <= -2 but better not too close to
 * -2 so that an underflow of the page_mapcount() won't be mistaken
 * for a genuine PAGE_BUDDY_MAPCOUNT_VALUE. -128 can be created very
 * efficiently by most CPU architectures.
 */
#define PAGE_BUDDY_MAPCOUNT_VALUE (-128)

static inline int PageBuddy(struct page *page)
{
    return atomic_read(&page->_mapcount) == PAGE_BUDDY_MAPCOUNT_VALUE;
}

static inline void __SetPageBuddy(struct page *page)
{
    VM_BUG_ON_PAGE(atomic_read(&page->_mapcount) != -1, page);
    atomic_set(&page->_mapcount, PAGE_BUDDY_MAPCOUNT_VALUE);
}

static inline void __ClearPageBuddy(struct page *page)
{
    VM_BUG_ON_PAGE(!PageBuddy(page), page);
    atomic_set(&page->_mapcount, -1);
}
```