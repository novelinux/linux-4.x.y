struct per_cpu_pages
========================================

count
----------------------------------------

count记录了与该列表相关的页的数目

path: include/linux/mmzone.h
```
struct per_cpu_pages {
    int count;        /* number of pages in the list */
```

high
----------------------------------------

high是一个水印。如果count的值超出了high，则表明列表中的页太多了。对容量过低的状态没有
显式使用水印：如果列表中没有成员，则重新填充。

```
    int high;        /* high watermark, emptying needed */
```

batch
----------------------------------------

如有可能，CPU的高速缓存不是用单个页来填充的，而是用多个页组成的块。batch是每次添加页数的一个参考值。

```
    int batch;        /* chunk size for buddy add/remove */
```

lists
----------------------------------------

list是一个双链表，保存了当前CPU的冷页和热页，可使用内核的标准方法处理。

```
    /* Lists of pages, one per migrate type stored on the pcp-lists */
    struct list_head lists[MIGRATE_PCPTYPES];
};
```