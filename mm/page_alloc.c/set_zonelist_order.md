set_zonelist_order
========================================

path: mm/page_alloc.c
```
static void set_zonelist_order(void)
{
    if (user_zonelist_order == ZONELIST_ORDER_DEFAULT)
        current_zonelist_order = default_zonelist_order();
    else
        current_zonelist_order = user_zonelist_order;
}
```

user_zonelist_order
----------------------------------------

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/mm/page_alloc.c/user_zonelist_order.md

current_zonelist_order
----------------------------------------

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/mm/page_alloc.c/current_zonelist_order.md

default_zonelist_order
----------------------------------------

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/mm/page_alloc.c/default_zonelist_order.md