## Linux内核预读机制

当内核发起一个读请求时（例如进程发起 read() 请求），首先会检查请求的数据是否缓存到了 pagecache 中。如果有，那么直接从内存中读取，不需要访问磁盘，这被称为 cache命中（cache hit）。如果 cache 中没有请求的数据，即 cache 未命中（cache miss），就必须从磁盘中读取数据。

然后内核将读取的数据缓存到 cache 中，这样后续的读请求就可以命中 cache 了。Page 可以只缓存一个文件部分的内容，不需要把整个文件都缓存进来。对磁盘的数据进行缓存从而提高性能主要是基于两个因素：

*  第一，磁盘访问的速度比内存慢好几个数量级（毫秒和纳秒的差距）。
*  第二是被访问过的数据，有很大概率会被再次访问。

结合 Android 系统实际来看，上层 App 每次读取磁盘时，文件系统默认会按 16 * 4k block 去磁盘读取数据，并把数据放到 pagecache 中。如果下次读取文件已经在 pagecache 中，则不会发生真实的磁盘 IO，而是直接从 pagecache中 读取，大大提升读的速度。有缓存就有回收，pagecache 的另一个重要工作是释放 page，从而释放内存空间。Cache 回收的任务是选择合适的 page 释放，并且如果 page 是 dirty 的，需要将 page 写回到磁盘中再释放。

理想的做法是释放距离下次访问时间最久的 page，但是很明显，这是不现实的。基于 LRU改进的 Two-List 是 Linux 使用的策略。这个回收策略非常类似业务开发领域，常见的图片加载的缓存策略。LRU 算法是选择最近一次访问时间最靠前的 page，即干掉最近没被光顾过的 page。原始 LRU 算法存在的问题是，有些文件只会被访问一次，但是按照 LRU 的算法，即使这些文件以后再也不会被访问了，但是如果它们是刚刚被访问的，就不会被选中。

Two-List 策略维护了两个list，active list 和 inactive list。在 active list 上的 page 被认为是 hot 的，不能释放。只有 inactive list 上的 page 可以被释放的。首次缓存的数据的 page 会被加入到 inactive list 中，已经在 inactive list 中的 page 如果再次被访问，就会移入 active list 中。两个链表都使用了伪 LRU 算法维护，新的 page 从尾部加入，移除时从头部移除，就像队列一样。

如果 active list 中 page 的数量远大于 inactive list，那么 active list 头部的页面会被移入 inactive list 中，从而维持两个表的平衡。简单的说，通过文件重布局的目的，就是将启动阶段需要用到的文件在 APK 文件中排布在一起，尽可能的利用 pagecache 机制，用最少的磁盘 IO 次数，读取尽可能多的启动阶段需要的文件，减少 IO 开销，从而达到提升启动性能的目的。


大多数磁盘I/O读写都是顺序的,且普通文件在磁盘上的存储都是占用连续的扇区。这样读写文件时,就可以减少磁头的移动次数,提升读写性能。当程序读一个文件时,它通常从第一字节到最后一个字节顺序访问。因此,同一个文件中磁盘上多个相邻的扇区通常会被读进程都访问。

预读(read ahead)就是在数据真正被访问之前,从普通文件或块设备文件中读取多个连续的文件页面到内存中。多数情况下,内核的预读机制可以明显提高磁盘性能,因为减少了磁盘控制器处理的命令数,每个命令读取多个相邻扇区。此外,预读机制还提高了系统响应时间。

当然,在进程大多数的访问是随机读时,预读是对系统有害的,因为它浪费了内核Cache空间。当内核确定最近常用的I/O访问不是顺序的时,就会减少或关闭预读。

预读(read-ahead)算法预测即将访问的页面,并提前把它们批量的读入缓存。它的主要功能和任务包括:

* 批量:把小I/O聚集为大I/O,以改善磁盘的利用率,提升系统的吞吐量。
* 提前:对应用程序隐藏磁盘的I/O延迟,以加快程序运行。
* 预测:这是预读算法的核心任务。前两个功能的达成都有赖于准确的预测能力。

当前包括Linux、 FreeBSD和Solaris等主流操作系统都遵循了一个简单有效的原则:

把读模式分为随机读和顺序读两大类,并只对顺序读进行预读。这一原则相对保守,但是可以保证很高的预读命中率,同时有效率/覆盖率也很好。因为顺序读是最简单而普遍的,而随机读在内核来说也确实是难以预测的。

在以下情况下,执行预读:

* 当内核处理用户进程的读文件数据请求;

此时调用page_cache_sync_readahead()或page_cache_async_readahead(),我们已看到它被函数do_generic_file_read()调用;该函数我们稍后会详细分析。

https://github.com/novelinux/system_calls/blob/master/fs/read/read.png

* 当内核为文件内存映射(memory mapping)分配一个页面时;
* 用户程序执行系统调用readahead();
* 当用户程序执行posix_fadvise()系统调用;
* 当用户程序执行madvise()系统调用,使用MADV_WILLNEED命令,来通知内核文件内存映射的特定区域将来会被访问。

**内核判断两次读访问是顺序的标准是:** 请求的第一个页面与上次访问的最后一个页面是相邻的。

访问一个给定的文件,预读算法使用两个页面集:当前窗口(current window)和前进窗口(ahead window)。
当前窗口(current window)包括了进程已请求的页面或内核提前读且在页面cache中的页面。(当前窗口中的页面未必是最新的,因为可能仍有I/O数据传输正在进行。)前进窗口(ahead window)包含的页面是紧邻当前窗口(current window)中内核提前读的页面。前进窗口中的页面没有被进程请求,但内核假设进程迟早会访问这些页面。当内核判断出一个顺序访问和初始页面属于当前窗口时,就检查前进窗口是否已经建立起来。若未建立,内核建立一个新的前进窗口,并且为对应的文件页面触发读操作。在理想状况下,进程正在访问的页面都在当前窗口中,而前进窗口中的文件页面正在传输。当进程访问的页面在前进窗口中时,前进窗口变为当前窗口。

### file_ra_state数据结构

[file_ra_state](../../include/linux/fs.h/struct_file_ra_state.md)

内核处理用户进程的读数据请求时,使用最多的是调用page_cache_sync_readahead
()和page_cache_async_readahead()函数来执行预读

do_generic_file_read()首先调用find_get_page()检查页是否已经包含在页缓存中。如果没有则调用page_cache_sync_readahead()发出一个同步预读请求。预读机制很大程度上能够保证数据已经进入缓存,因此再次调用find_get_page()查找该页。这次仍然有一定失败的概率,那么就跳转到标号no_cached_page处直接进行读取操作。检测页标志是否设置了PG_readahead,如果设置了该标志就调用page_cache_async_readahead()启动一个异步预读操作,这与前面的同步预读操作不同,这里并不等待预读操作的结束。虽然页在缓存中了,但是其数据不一定是最新的,这里通过PageUptodate(page)来检查。如果数据不是最新的,则调用函数mapping->a_ops->readpage()进行再次数据读取。

本章节重点分析预读代码。

### page_cache_sync_readahead

[page_cache_sync_readahead](./page_cache_sync_readahead.md)

### page_cache_async_readahead

[page_cache_async_readahead](./page_cache_async_readahead.md)

### ondemand_readahead

[ondemand_readahead](./ondemand_readahead.md)