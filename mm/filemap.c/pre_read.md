## Pre Read

当内核发起一个读请求时（例如进程发起 read() 请求），首先会检查请求的数据是否缓存到了 pagecache 中。如果有，那么直接从内存中读取，不需要访问磁盘，这被称为 cache命中（cache hit）。如果 cache 中没有请求的数据，即 cache 未命中（cache miss），就必须从磁盘中读取数据。

然后内核将读取的数据缓存到 cache 中，这样后续的读请求就可以命中 cache 了。Page 可以只缓存一个文件部分的内容，不需要把整个文件都缓存进来。对磁盘的数据进行缓存从而提高性能主要是基于两个因素：

*  第一，磁盘访问的速度比内存慢好几个数量级（毫秒和纳秒的差距）。
*  第二是被访问过的数据，有很大概率会被再次访问。

结合 Android 系统实际来看，上层 App 每次读取磁盘时，文件系统默认会按 16 * 4k block 去磁盘读取数据，并把数据放到 pagecache 中。如果下次读取文件已经在 pagecache 中，则不会发生真实的磁盘 IO，而是直接从 pagecache中 读取，大大提升读的速度。有缓存就有回收，pagecache 的另一个重要工作是释放 page，从而释放内存空间。Cache 回收的任务是选择合适的 page 释放，并且如果 page 是 dirty 的，需要将 page 写回到磁盘中再释放。

理想的做法是释放距离下次访问时间最久的 page，但是很明显，这是不现实的。基于 LRU改进的 Two-List 是 Linux 使用的策略。这个回收策略非常类似业务开发领域，常见的图片加载的缓存策略。LRU 算法是选择最近一次访问时间最靠前的 page，即干掉最近没被光顾过的 page。原始 LRU 算法存在的问题是，有些文件只会被访问一次，但是按照 LRU 的算法，即使这些文件以后再也不会被访问了，但是如果它们是刚刚被访问的，就不会被选中。

Two-List 策略维护了两个list，active list 和 inactive list。在 active list 上的 page 被认为是 hot 的，不能释放。只有 inactive list 上的 page 可以被释放的。首次缓存的数据的 page 会被加入到 inactive list 中，已经在 inactive list 中的 page 如果再次被访问，就会移入 active list 中。两个链表都使用了伪 LRU 算法维护，新的 page 从尾部加入，移除时从头部移除，就像队列一样。

如果 active list 中 page 的数量远大于 inactive list，那么 active list 头部的页面会被移入 inactive list 中，从而维持两个表的平衡。简单的说，通过文件重布局的目的，就是将启动阶段需要用到的文件在 APK 文件中排布在一起，尽可能的利用 pagecache 机制，用最少的磁盘 IO 次数，读取尽可能多的启动阶段需要的文件，减少 IO 开销，从而达到提升启动性能的目的。
