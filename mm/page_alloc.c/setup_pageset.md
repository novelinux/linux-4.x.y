setup_pageset
========================================

pageset_init
----------------------------------------

path: mm/page_alloc.c
```
static void setup_pageset(struct per_cpu_pageset *p, unsigned long batch)
{
    pageset_init(p);
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/pageset_init.md

pageset_set_batch
----------------------------------------

```
    pageset_set_batch(p, batch);
}
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/pageset_set_batch.md
