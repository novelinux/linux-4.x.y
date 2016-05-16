struct free_area
========================================

free_list
----------------------------------------

path: include/linux/mmzone.h
```
struct free_area {
       struct list_head free_list[MIGRATE_TYPES];
```

free_list是用于连接空闲页的链表。页链表包含大小相同的连续内存区, 对伙伴系统数据结构的主要调整，
是将空闲列表分解为MIGRATE_TYPE个列表,目的是为了减少碎片.

### MIGRATE_TYPES

https://github.com/novelinux/linux-4.x.y/blob/master/include/linux/mmzone.h/MIGRATE_TYPES.md

nr_free
----------------------------------------

```
       unsigned long    nr_free;
};
```

nr_free指定了当前内存区中空闲页块的数目, 统计了所有列表上空闲页的数目，而每种迁移类型都对应于
一个空闲列表。对0阶内存区逐页计算，对1阶内存区计算页对的数目，对2阶内存区计算4页集合的数目，
依次类推。阶是伙伴系统中一个非常重要的术语。它描述了内存分配的数量单位。内存块的长度是2^order，
其中order的范围从0到MAX_ORDER。

### MAX_ORDER

https://github.com/novelinux/linux-4.x.y/blob/master/include/linux/mmzone.h/MAX_ORDER.md
