pageset_init
========================================

path: mm/page_alloc.c
```
static void pageset_init(struct per_cpu_pageset *p)
{
    struct per_cpu_pages *pcp;
    int migratetype;

    memset(p, 0, sizeof(*p));

    pcp = &p->pcp;
    pcp->count = 0;
    for (migratetype = 0; migratetype < MIGRATE_PCPTYPES; migratetype++)
        INIT_LIST_HEAD(&pcp->lists[migratetype]);
}
```