## struct file_ra_state

### start

当前窗口的第一个页面索引

```
/*
 * Track a single file's readahead state
 */
struct file_ra_state {
	pgoff_t start;			/* where readahead started */
```

### size

```
	unsigned int size;		/* # of readahead pages */
```

当前窗口的页面数量。值为-1表示预读临时关闭,0表示当前窗口为空

### async_size

异步预读页面数量

```
	unsigned int async_size;	/* do asynchronous readahead when
					   there are only # of pages ahead */
```

### ra_pages

预读窗口最大页面数量。0表示预读暂时关闭。

```
	unsigned int ra_pages;		/* Maximum readahead window */
```

### mmap_miss

预读失效计数

```
	unsigned int mmap_miss;		/* Cache miss stat for mmap accesses */
```

### prev_pos

Cache中最近一次读位置

```
	loff_t prev_pos;		/* Cache last read() position */
};
```

ra_pages表示当前窗口的最大页面数,也就是针对该文件的最大预读页面数;其初始值由该文件所在块设备上的backing_dev_info描述符中。进程可以通过系统调用posix_fadvise()来改变已打开文件的ra_page值来调优预读算法。o