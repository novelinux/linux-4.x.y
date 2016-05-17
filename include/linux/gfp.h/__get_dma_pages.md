__get_dma_pages
========================================

path: include/linux/gfp.h
```
#define __get_dma_pages(gfp_mask, order) \
          __get_free_pages((gfp_mask) | GFP_DMA, (order))
```

__get_free_pages
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/__get_free_pages.md
