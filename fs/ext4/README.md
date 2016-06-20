EXT4
========================================

本文描述Ext4文件系统磁盘布局和元数据的一些分析，同样适用于Ext3和Ext2文件系统，
除了它们不支持的Ext4的特性外。

一个Ext4文件系统被分成一系列块组。为减少磁盘碎片产生的性能瓶颈，块分配器尽量保持每个文件的
数据块都在同一个块组中，从而减少寻道时间。以4KB的数据块为例，一个块组可以包含32768个数据块，
也就是128MB.

Disk Layout
----------------------------------------

### File System Layout

![fs_layout.jpg](https://github.com/novelinux/linux-4.x.y/tree/master/fs/ext4/res/fs_layout.jpg)

启动扇区是硬盘上的一个区域，在系统加电启动时，其内容由BIOS自动装载并执行。它包含一个启动
装载程序，用于从计算机安装的操作系统中选择一个启动，还负责继续启动过程。显然，该区域不可
能填充文件系统的数据。启动装载程序并非在所有系统上都是必需的。在需要启动装载程序的系统上，
它们通常位于硬盘的起始处，以避免影响其后的分区。

磁盘上剩余的空间由连续的许多块组占用，存储了文件系统元数据和各个文件的有用数据，
每个块组包含许多冗余信息。

### Block Group Layout

![bg_layout.jpg](https://github.com/novelinux/linux-4.x.y/tree/master/fs/ext4/res/bg_layout.jpg)

* 超级块

是用于存储文件系统自身元数据的核心结构。其中的信息包括空闲与已使用块的数目、块长度、
当前文件系统状态（在启动时用于检测前一次崩溃）、各种时间戳（例如，上一次装载文件系统
的时间以及上一次写入操作的时间）。它还包括一个表示文件系统类型的魔数，这样mount例程
能够确认文件系统的类型是否正确。内核只使用第一个块组的超级块读取文件系统的元信息，即
使在几个超级块中都有超级块，也是如此。

* 组描述符

包含的信息反映了文件系统中各个块组的状态，例如，块组中空闲块和inode的数目。每个块组
都包含了文件系统中所有块组的组描述符信息。

* 数据块位图和inode位图

用于保存长的比特位串。这些结构中的每个比特位都对应于一个数据块或inode，用于表示对应的数据块
或inode是空闲的，还是被使用中。

* inode表

包含了块组中所有的inode，inode用于保存文件系统中与各个文件和目录相关的所有元数据。

* 数据块

包含了文件系统中的文件的有用数据。

**数据块和Inode分配策略**:

在机械磁盘上，保持相关的数据块相互接近可以总的磁头移动时间，因而可以加速磁盘IO。在SSD上
虽然没有磁头转动，数据局部性可以增加每次IO请求的传输的数据大小，因而减少响应IO请求的
传输次数。数据的局部性对单个擦除块的写入产生影响，可以加速文件重写的速度。因而尽可能
减少碎片是必要的。inode和数据块的分配策略可以保证数据的局部集中。以下为inode和数据块的分配策略：

* 1.多块分配可以减少磁盘碎片。当文件初次创建的时候，块分配器预测性地分配8KB的磁盘空间给文件。
当文件关闭的时候，未使用的空间当然也就释放了。但是如果推测是正确的，那么文件数据将写到一个
多个块的extent中。
* 2.延迟分配。当一个文件需要更多的数据块引起写操作时，文件系统推迟决定新数据在磁盘上的存放位置，
直到脏的buffer写到磁盘为止。
* 3.尽量保持文件的数据块与其inode在同一个块组中。可以减少磁盘寻道时间.
* 4.尽量保持同一个目录中的所有inodes与目录位于同一个块组中。这样的假设前提是一个目录中的
文件是相关的。
* 5.磁盘卷被分成128MB的块组。当在根目录中创建目录时，inode分配器扫描块组并将新目录放到
它找到的使用负荷最小的块组中。这可以保证目录在磁盘上的分散性。
* 6.即使上述机制无效，仍然可以使用e4defrag整理碎片文件。

dumpe2fs
----------------------------------------

dumpe2fs可以查看磁盘上对应ext4文件系统信息，如下所示:

```
# dumpe2fs /dev/block/bootdevice/by-name/cust
dumpe2fs 1.42.9 (28-Dec-2013)
Filesystem volume name:   cust
Last mounted on:          /cust
Filesystem UUID:          f00b9a3b-4d08-c450-8c71-e78719096954
Filesystem magic number:  0xEF53
Filesystem revision #:    1 (dynamic)
Filesystem features:      has_journal ext_attr resize_inode filetype needs_recovery extent sparse_super large_file uninit_bg
Filesystem flags:         unsigned_directory_hash
Default mount options:    (none)
Filesystem state:         clean
Errors behavior:          Remount read-only
Filesystem OS type:       Linux
Inode count:              32768
Block count:              131072
Reserved block count:     0
Free blocks:              1612
Free inodes:              32708
First block:              0
Block size:               4096
Fragment size:            4096
Reserved GDT blocks:      31
Blocks per group:         32768
Fragments per group:      32768
Inodes per group:         8192
Inode blocks per group:   512
Last mount time:          Mon Jun 20 09:38:41 2016
Last write time:          Mon Jun 20 09:38:41 2016
Mount count:              1
Maximum mount count:      -1
Last checked:             Thu Jan  1 08:00:00 1970
Check interval:           0 (<none>)
Reserved blocks uid:      0 (user root)
Reserved blocks gid:      0 (group root)
First inode:              11
Inode size:                         256
Required extra isize:     28
Desired extra isize:      28
Journal inode:            8
Default directory hash:   tea
Journal backup:           inode blocks
Journal features:         (none)
Journal size:             8M
Journal length:           2048
Journal sequence:         0x00000002
Journal start:            1


Group 0: (Blocks 0-32767) [ITABLE_ZEROED]
  Checksum 0x5ac5, unused inodes 0
  Primary superblock at 0, Group descriptors at 1-1
  Reserved GDT blocks at 2-32
  Block bitmap at 33 (+33), Inode bitmap at 34 (+34)
  Inode table at 35-546 (+35)
  349 free blocks, 8132 free inodes, 26 directories
  Free blocks: 32419-32767
  Free inodes: 61-8192
Group 1: (Blocks 32768-65535) [INODE_UNINIT, ITABLE_ZEROED]
  Checksum 0x01a5, unused inodes 0
  Backup superblock at 32768, Group descriptors at 32769-32769
  Reserved GDT blocks at 32770-32800
  Block bitmap at 32801 (+33), Inode bitmap at 32802 (+34)
  Inode table at 32803-33314 (+35)
  6567 free blocks, 8192 free inodes, 0 directories
  Free blocks: 46450-51754, 64274-65535
  Free inodes: 8193-16384
Group 2: (Blocks 65536-98303) [INODE_UNINIT, ITABLE_ZEROED]
  Checksum 0x3504, unused inodes 0
  Block bitmap at 65536 (+0), Inode bitmap at 65537 (+1)
  Inode table at 65538-66049 (+2)
  1 free blocks, 8192 free inodes, 0 directories
  Free blocks: 98303
  Free inodes: 16385-24576
Group 3: (Blocks 98304-131071) [INODE_UNINIT, ITABLE_ZEROED]
  Checksum 0x9f8f, unused inodes 0
  Backup superblock at 98304, Group descriptors at 98305-98305
  Reserved GDT blocks at 98306-98336
  Block bitmap at 98337 (+33), Inode bitmap at 98338 (+34)
  Inode table at 98339-98850 (+35)
  0 free blocks, 8192 free inodes, 0 directories
  Free blocks:
  Free inodes: 24577-32768
```

Data Structure
----------------------------------------

### Flex Group

https://github.com/novelinux/linux-4.x.y/blob/master/fs/ext4/ext4.h/struct_flex_groups.md

### Super Block

#### On Disk

https://github.com/novelinux/linux-4.x.y/blob/master/fs/ext4/ext4.h/struct_ext4_super_block.md

#### On Memory

https://github.com/novelinux/linux-4.x.y/blob/master/fs/ext4/ext4.h/struct_ext4_sb_info.md

### Group Descriptor

https://github.com/novelinux/linux-4.x.y/blob/master/fs/ext4/ext4.h/struct_ext4_group_desc.md

### Inode

#### On Disk

https://github.com/novelinux/linux-4.x.y/blob/master/fs/ext4/ext4.h/struct_ext4_inode.md

#### On Memory

https://github.com/novelinux/linux-4.x.y/blob/master/fs/ext4/ext4.h/struct_ext4_inode_info.md

### Dir vs File

https://github.com/novelinux/linux-4.x.y/blob/master/fs/ext4/ext4.h/struct_ext4_dir_entry_2.md

**Notes**:

为避免经常从低速的硬盘读取管理数据结构，Linux将这些结构包含的最重要的信息保存在特别的数据结构，
持久驻留在物理内存中。这样访问速度就快了很多，也减少了与硬盘的交互。那么为什么不将所有的文件
系统管理数据保存在物理内存中（定期将修改写回磁盘）？尽管这在理论上是可能的，但在实际上行不通，
因为对以吉字节计算的大硬盘来说（现在很常见），需要大量内存来保存所有的块位图和inode位图。
