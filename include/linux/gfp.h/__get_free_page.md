__get_free_page
========================================

path: include/linux/gfp.h
```
#define __get_free_page(gfp_mask) \
          __get_free_pages((gfp_mask), 0)
```

__get_free_pages
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/__get_free_pages.md
