struct block_device
========================================

块设备的核心属性由struct block_device表示。

bd_dev
----------------------------------------

path: include/linux/fs.h
```
struct block_device {
    dev_t            bd_dev;  /* not a kdev_t - it's a search key */
```

块设备的设备号保存在bd_dev。

bd_openers
----------------------------------------

```
    int            bd_openers;
```

bd_openers统计用do_open打开该块设备的次数。

bd_inode
----------------------------------------

```
    struct inode *        bd_inode;    /* will die */
    struct super_block *    bd_super;
    struct mutex        bd_mutex;    /* open/close mutex */
    struct list_head    bd_inodes;
    void *            bd_claiming;
    void *            bd_holder;
    int            bd_holders;
    bool            bd_write_holder;
#ifdef CONFIG_SYSFS
    struct list_head    bd_holder_disks;
#endif
    struct block_device *    bd_contains;
    unsigned        bd_block_size;
```

bd_part
----------------------------------------

```
    struct hd_struct *    bd_part;
```

bd_part指向一个专用的数据结构（struct hd_struct），表示包含在该块设备上的分区。

bd_part_count
----------------------------------------

```
    /* number of times partitions within this device have been opened. */
    unsigned        bd_part_count;
```

bd_part_count不像假定的那样统计了分区的数目。相反，它是一个使用计数，计算了内核中
引用该设备内分区的次数。在用rescan_partitions重新扫描分区时，这个计数很有必要。
如果bd_part_count大于零，则禁止重新扫描，因为旧的分区仍然在使用中。

bd_invalidated
----------------------------------------

```
    int            bd_invalidated;
```

bd_invalidated设置为1，表示该分区在内核中的信息无效，因为磁盘上的分区已经改变。
下一次打开该设备时，将要重新扫描分区表。

bd_disk
----------------------------------------

```
    struct gendisk *    bd_disk;
```

bd_disk提供了另一个抽象层，也用来划分硬盘。

bd_queue
----------------------------------------

```
    struct request_queue *  bd_queue;
```

bd_list
----------------------------------------

```
    struct list_head    bd_list;
```

bd_list是一个链表元素，用于跟踪记录系统中所有可用的block_device实例。
该链表的表头为全局变量all_bdevs。使用该链表，无需查询块设备数据库，
即可遍历所有块设备。

bd_private
----------------------------------------

```
    /*
     * Private data.  You must have bd_claim'ed the block_device
     * to use this.  NOTE:  bd_claim allows an owner to claim
     * the same device multiple times, the owner must take special
     * care to not mess up bd_private for that case.
     */
    unsigned long        bd_private;
```

bd_private可用于在block_device实例中存储特定于持有者的数据。
术语“特定于持有者”意味着，只有该block_device实例当前的持有者
可以使用bd_private。要成为持有者，必须对块设备成功调用bd_claim。
bd_claim在bd_holder是NULL指针时才会成功，即尚未注册持有者。
在这种情况下，bd_holder指向当前持有者，可以是内核空间中任意一个地址。
调用bd_claim，实际上是向内核的其他部分表明，该块设备已经与之无关了。

关于内核的哪个部分允许持有块设备，没有固定的规则。例如在Ext3文件系统中，
会持有已装载文件系统的外部日志的块设备，并将超级块注册为持有者。如果
某个分区用作交换区，那么在用swapon系统调用激活该分区之后，页交换代码将持有该分区。
在使用blkdev_open打开块设备并请求独占使用时，与该设备文件关联的file实例会持有该块设备。

```
    /* The counter of freeze processes */
    int            bd_fsfreeze_count;
    /* Mutex for freeze */
    struct mutex        bd_fsfreeze_mutex;
};
```