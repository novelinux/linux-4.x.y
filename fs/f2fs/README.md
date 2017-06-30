# 1 F2FS文件系统简介

F2FS (Flash Friendly File System) 是专门为基于 NAND 的存储设备设计的新型开源 flash 文件系统。特别针对NAND 闪存存储介质做了友好设计。F2FS 于2012年12月进入Linux 3.8 内核。目前，F2FS仅支持linux操作系统。
F2FS 选择 log-structured文件系统方案，并使之更加适应新的存储介质(NAND)。同时，修复了旧式日志结构文件系统的一些已知问题，如(1) wandering tree 的滚雪球效应和(2)高清理开销。
根据内部几何结构和闪存管理机制(FTL)，闪存存储设备有很多不同的属性，所以F2FS的设计者增加了多种参数，不仅用于配置磁盘布局，还可以选择分配和清理算法，优化性能(并行IO提高性能)。

## 1.1 F2FS文件系统的设计背景和要解决的主要问题

### 1.1.1 LFS（Log-strctured File System）

为管理磁盘上的大的连续的空间以便快速写入数据，将 log 切分成 Segments，使用 Segment Cleaner 从重度碎片化的 Segment 中转移出有效的信息，然后将该 Segment 清理干净用于后续写入数据。

### 1.1.2 Wandering Tree 问题

在 LFS 中，当文件的数据块被更新的时候是写到 log 的末尾，该数据块的直接指针也因为数据位置的改变而更改，然后间接指针块也因为直接指针块的更新而更新。按照这种方式，上层的索引结构，如inode、inode map 以及 checkpoint block 也会递归地更新。这就是所谓的 wandering tree 问题。为了提高性能，数据块更新的时候应该尽可能地消除或减少wandering tree 的更新节点传播。

### 1.1.3 Cleaning 开销

为了产生新的 log 空闲空间，LFS 需要回收无效的数据块，释放出空闲空间，这一过程称为 Cleaning 过程。Cleaning 过程包含如下操作：
* (1)    通过查找 segment 使用情况链表，选择一个 segment；
* (2)    通过 segment summary block 识别出选中的 segment 中的所有数据块的父索引结构并载入到内存；
* (3)    检查数据及其父索引结构的交叉引用；
* (4)    选择有效数据进行转移有效数据。
Cleaning  工作可能会引起难以预料的长延时，因而 LFS 要解决的一个重要问题是对用户隐藏这种延时，并且应当减少需要转移的数据的总量以及快速转移数据。

# 2 F2FS文件系统特性和功能

## 2.1 F2FS不支持的特性和功能（后续可能会支持）

当前F2FS不支持如下的特性，但是这些特性在以后如果必要的话也会支持：
* (1)    快照
* (2)    用户配额——最难实现
* (3)    不支持NFS
* (4)    不支持“security”方面的扩展特性(xattrs)

## 2.2 F2FS的特性和功能
F2FS具有以下特性和功能：
* (1)    最大文件系统16TB；
* (2)    32位块寻址空间；
* (3)    最大文件大小3.94TB；
* (4)    Log-structured；
* (5)    Flash 感知
a) 扩大随机写区域（元数据区域，two-location）以获取更好的性能；
b) 尽量使 F2FS 的数据结构与 FTL 的运算部件对齐。
* (6)    解决Wandering Tree 问题
a) 用术语“node”表示 inode 以及各种索引指针块；
b) 引入 Node Address Table (NAT) 包含所有“node”块的位置，这将切断数据块更新的递归传播。
* (7)    最小化Cleaning 开销
a) 支持后台 Cleaning 进程；
b) 支持 greedy 和 低成本(转移数据最少)的待清理 Section 选择算法；
c) 支持 multi-head logs 用于动态/静态 hot 与 cold 数据分离；
d) 引入自适应 logging 用于有效块分配。

# F2FS文件系统的磁盘布局分析

F2FS 将整个卷切分成大量的 Segments，每个 Segment 的大小是固定的2 MB。
连续的若干个Segments 构成 Section，连续的若干个 Sections 构成 Zone。
默认情况下一个 Zone 大的大小是一个 Section，而一个 Section 的大小是一个 Segment。
F2FS 将整个卷切分成6个区域，除了超级块(Superblock，SB)外，其余每个区域都包含多个 Segments。

On-disk Layout
--------------

F2FS divides the whole volume into a number of segments, each of which is fixed
to 2MB in size. A section is composed of consecutive segments, and a zone
consists of a set of sections. By default, section and zone sizes are set to one
segment size identically, but users can easily modify the sizes by mkfs.

F2FS splits the entire volume into six areas, and all the areas except superblock
consists of multiple segments as described below.

                                            align with the zone size <-|
                 |-> align with the segment size
     _________________________________________________________________________
    |            |            |   Segment   |    Node     |   Segment  |      |
    | Superblock | Checkpoint |    Info.    |   Address   |   Summary  | Main |
    |    (SB)    |   (CP)     | Table (SIT) | Table (NAT) | Area (SSA) |      |
    |____________|_____2______|______N______|______N______|______N_____|__N___|
                                                                       .      .
                                                             .                .
                                                 .                            .
                                    ._________________________________________.
                                    |_Segment_|_..._|_Segment_|_..._|_Segment_|
                                    .           .
                                    ._________._________
                                    |_section_|__...__|_
                                    .            .
		                    .________.
	                            |__zone__|

- Superblock (SB)
 : It is located at the beginning of the partition, and there exist two copies
   to avoid file system crash. It contains basic partition information and some
   default parameters of f2fs.

- Checkpoint (CP)
 : It contains file system information, bitmaps for valid NAT/SIT sets, orphan
   inode lists, and summary entries of current active segments.

- Segment Information Table (SIT)
 : It contains segment information such as valid block count and bitmap for the
   validity of all the blocks.

- Node Address Table (NAT)
 : It is composed of a block address table for all the node blocks stored in
   Main area.

- Segment Summary Area (SSA)
 : It contains summary entries which contains the owner information of all the
   data and node blocks stored in Main area.

- Main Area
 : It contains file and directory data including their indices.

In order to avoid misalignment between file system and flash-based storage, F2FS
aligns the start block address of CP with the segment size. Also, it aligns the
start block address of Main area with the zone size by reserving some segments
in SSA area.

Reference the following survey for additional technical details.
https://wiki.linaro.org/WorkingGroups/Kernel/Projects/FlashCardSurvey
