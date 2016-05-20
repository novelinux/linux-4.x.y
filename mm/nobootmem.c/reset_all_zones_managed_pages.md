reset_all_zones_managed_pages
========================================

path: mm/nobootmem.c
```
static int reset_managed_pages_done __initdata;

...

void __init reset_all_zones_managed_pages(void)
{
    struct pglist_data *pgdat;

    if (reset_managed_pages_done)
        return;

    for_each_online_pgdat(pgdat)
        reset_node_managed_pages(pgdat);

    reset_managed_pages_done = 1;
}
```

reset_node_managed_pages
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/nobootmem.c/reset_node_managed_pages.md
