enum zone_watermarks
========================================

path: include/linux/mmzone.h
```
enum zone_watermarks {
    WMARK_MIN,
    WMARK_LOW,
    WMARK_HIGH,
    NR_WMARK
};
```

min_free_kbytes
----------------------------------------

内核有一个参数，当系统内存使用到一定量的时候，会自动触动回收操作。

```
# cat /proc/sys/vm/min_free_kbytes
```

代表系统所保留空闲内存的最低限,在系统初始化时会根据内存大小计算一个默认值，计算规则是:

```
min_free_kbytes = sqrt(lowmem_kbytes * 16) = 4 * sqrt(lowmem_kbytes)
```

**注**: lowmem_kbytes即可认为是系统内存大小

另外，计算出来的值有最小最大限制，最小为128K，最大为64M。

可以看出，min_free_kbytes随着系统内存的增大不是线性增长，因为随着内存的增大，
没有必要也线性的预留出过多的内存，能保证紧急时刻的使用量便足矣。

min_free_kbytes的主要用途是计算影响内存回收的三个参数: watermark[min/low/high]

1.watermark[high] > watermark [low] > watermark[min]，各个zone各一套

2.在系统空闲内存低于 watermark[low]时，开始启动内核线程kswapd进行内存回收（每个zone一个），
  直到该zone的空闲内存数量达到watermark[high]后停止回收。如果上层申请内存的速度太快，
  导致空闲内存降至watermark[min]后，内核就会进行direct reclaim(直接回收)，即直接在
  应用程序的进程上下文中进行回收，再用回收上来的空闲页满足内存申请，因此实际会阻塞应用程序，
  带来一定的响应延迟，而且可能会触发系统OOM。这是因为watermark[min]以下的内存属于系统的自留内存，
  用以满足特殊使用，所以不会给用户态的普通申请来用。

3.三个watermark的计算方法：

因为是每个zone各有一套watermark参数，实际计算效果是根据各个zone大小所占内存总大小的比例.

```
watermark[min] = min_free_kbytes换算为page单位即可，假设为min_free_pages。
watermark[low] = watermark[min] * 5 / 4
watermark[high] = watermark[min] * 3 / 2
```

4.可以通过/proc/zoneinfo查看每个zone的watermark

```
Node 0, zone      DMA
pages free     3960
min      65
low      81
high     97
```

5.min_free_kbytes大小的影响

min_free_kbytes设的越大，watermark的线越高，同时三个线之间的buffer量也相应会增加。这意味着会较早
的启动kswapd进行回收，且会回收上来较多的内存（直至watermark[high]才会停止），这会使得系统预留过
多的空闲内存，从而在一定程度上降低了应用程序可使用的内存量。极端情况下设置min_free_kbytes接近
内存大小时，留给应用程序的内存就会太少而可能会频繁地导致OOM的发生。

min_free_kbytes设的过小，则会导致系统预留内存过小。kswapd回收的过程中也会有少量的内存分配行为
（会设上PF_MEMALLOC）标志，这个标志会允许kswapd使用预留内存；另外一种情况是被OOM选中杀死的进程
在退出过程中，如果需要申请内存也可以使用预留部分。这两种情况下让他们使用预留内存可以避免系统
进入deadlock状态。

最终查明，slab cache占用过多属于正常问题，并且当内存到达系统最低空闲内存限制的话，会自动触发
kswapd进程来回收内存，属于正常现象。

注：测了一下，当调整完min_free_kbytes值大于系统空闲内存后，kswapd进程的确从休眠状态进入运行态，
开始回收内存。

```
vm.vfs_cache_pressure = 200
```

该文件表示内核回收用于directory和inode cache内存的倾向；缺省值100表示内核将根据
pagecache和swapcache，把directory和inode cache保持在一个合理的百分比；降低该值低于100，
将导致内核倾向于保留directory和inode cache；增加该值超过100，将导致内核倾向于回收
directory和inode cache。

所以加快kswapd内存的回收。