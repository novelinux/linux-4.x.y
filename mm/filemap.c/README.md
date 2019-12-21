# Linux内核文件Cache机制

在我们使用Linux时，使用free命令观察系统内存使用情况，如下面空间内存为66053100k。可能很多同事都遇到过一个问题，发现随着时间的推移，内存的free越来越小，而cached越来越大；于是就以为是不是自己的程序存在内存泄漏，或者是硬件、操作系统出了问题？显然，从这里看不出用户程序是否有内存泄漏，也不是内核有Bug或硬件有问题。原因是内核的文件Cache机制。实际上文件Cache的实现是页面Cache，本文后续都以页面Cache来描述。

```
[root@localhost ~]# free
             total       used       free     shared    buffers     cached
Mem:      66053100    1727572   64325528          0     242492     409440
-/+ buffers/cache:    1075640   64977460
Swap:      2097144          0    2097144
```

当应用程序需要读取文件中的数据时，操作系统先分配一些内存，将数据从存储设备读入到这些内存中，然后再将数据分发给应用程序；当需要往文件中写数据时，操作系统先分配内存接收用户数据，然后再将数据从内存写到磁盘上。文件Cache管理指的就是对这些由操作系统内核分配，并用来存储文件数据的内存管理。

在大部分情况下，内核在读写磁盘时都先通过页面Cache。若页面不在Cache中，新页加入到页面Cache中，并用从磁盘上读来的数据来填充页面。如果内存有足够的内存空间，该页可以在页面Cache长时间驻留，其他进程再访问该部分数据时，不需要访问磁盘。这就是free命令显示内核free值越来越小，cached值越来越大的原因。

同样，在把一页数据写到块设备之前，内核首先检查对应的页是否已经在页面Cache中；如果不在，就在页面Cache增加一个新页面，并用要写到磁盘的数据来填充。数据的I/O传输并不会立即开始执行，而是会延迟几秒左右；这样进程就有机会进一步修改写到磁盘的数据。

内核的代码和数据结构不必从磁盘读，也不必写入磁盘。

内核的代码和数据结构不必从磁盘读,也不必写入磁盘。因此页面Cache可能是下面的类型:

* 含有普通文件数据的页;
* 含有目录的页;
* 含有直接从块设备文件(跳过文件系统层)读出的数据页;
* 含有用户态进程数据的页,但页中的数据已被交换到磁盘;
* 属于特殊文件系统的页,如进程间通信中的特殊文件系统shm

块设备I/O操作流程图,从图中我们可以看出具体文件系统(如ext3/ext4、 xfs等),负责在文件Cache和存储设备之间交换数据,位于具体文件系统之上的虚拟文件系统VFS负责在应用程序和文件 Cache 之间通过read()/write()等接口交换数据。

[Read/Write](./read-write.png)

页面Cache中的每页所包含的数据是属于某个文件,这个文件(准确地说是文件的inode)就是该页的拥有者。事实上,所有的read()和write()都依赖于页面Cache;唯一的例外是当进程打开文件时,使用了O_DIRECT标志,在这种情况下,页面Cache被跳过,且使用了进程用户态地址空间的缓冲区。有些数据库应用程序使用O_DIRECT标志,这样他们可以使用自己的磁盘缓冲算法。

内核页面Cache的实现主要为了满足下面两种需要:

* 快速定位含有给定所有者相关数据的特定页。为了尽可能发挥页面Cache的优势,查找过程必须是快速的。

* 记录在读或写页中的数据时,应该如何处理页面Cache中的每个页。例如,从普通文件、块设备文件或交换区读一个数据页,必须用不同的方式;这样内核必须根据页面拥有者来选择正确的操作。

显然,页面Cache中的数据单位是整页数据。当然一个页面中的数据在磁盘上不必是相邻的,这样页面就不能用设备号和块号来识别。取而代之的是,Cache中的页面识别是通过拥有者和拥有者数据中的索引,通常是inode和相应文件内的偏移量。文件Cache是文件数据在内存中的副本,因此文件Cache管理与内存管理系统和文件系统都相关:一方面文件 Cache 作为物理内存的一部分,需要参与物理内存的分配回收过程,另一方面文件Cache中的数据来源于存储设备上的文件,需要通过文件系统与存储设备进行读写交互。从操作系统的角度考虑,文件Cache可以看做是内存管理系统与文件系统之间的联系纽带。因此,文件Cache管理是操作系统的一个重要组成部分,它的性能直接影响着文件系统和内存管理系统的性能。

### Cache重要数据结构和函数

#### address_space

[Address Space](../../include/linux/fs.h/struct_address_space.md)

对页面Cache操作的基本高级函数有查找、增加和删除页:

* find_get_page

find_get_page()的参数有两个:address_space对象的指针和文件页面偏移量。若在xarray中找到了指定页,就增加该页的计数。

[find_get_page](../../include/linux/pagemap.h/find_get_page.md)

* add_to_page_cache_locked

函数add_to_page_cache_locked()的作用是将一个新页插入到页面Cache中

[add_to_page_cache_locked](./add_to_page_cache_locked.md)

* delete_from_page_cache

是从页面Cache中删除某个页

[delete_from_page_cache](./delete_from_page_cache.md)

### Free命令显示内存

[Free](./free.jpg)

* Mem：表示物理内存统计。
* total：表示物理内存总量(total = used + free)。
* used：表示总计分配给缓存（包含buffers 与cache ）使用的数量，但其中可能部分缓存并未实际使用。
* free：未被分配的内存。
* shared：共享内存。
* buffers：系统分配但未被使用的buffers数量。
* cached：系统分配但未被使用的cache数量。
* -/+ buffers/cache：表示物理内存的缓存统计。
* used2：也就是第一行中的used – buffers - cached也是实际使用的内存总量。 // used2为第二行
* free2 = buffers1 + cached1 + free1 // free2为第二行，buffers1等为第一行
* free2：未被使用的buffers与cache和未被分配的内存之和，这就是系统当前实际可用内存。
* Swap：表示硬盘上交换分区的使用情况。

在Free命令中显示的buffer和cache，它们都是占用内存：

* buffer : 作为buffer cache的内存，是块设备的读写缓冲区，更靠近存储设备，或者直接就是disk的缓冲区。
* cache: 作为page cache的内存, 文件系统的cache，是memory的缓冲区 。

如果cache 的值很大，说明cache住的文件数很多。如果频繁访问到的文件都能被cache住，那么磁盘的读IO 必会非常小 。

#### Page cache（页面缓存）

Page cache 也叫页缓冲或文件缓冲，是由好几个磁盘块构成，大小通常为4k，在64位系统上为8k，构成的几个磁盘块在物理磁盘上不一定连续，文件的组织单位为一页， 也就是一个page cache大小，文件读取是由外存上不连续的几个磁盘块，到buffer cache，然后组成page cache，然后供给应用程序。

Page cache在linux读写文件时，它用于缓存文件的逻辑内容，从而加快对磁盘上映像和数据的访问。具体说是加速对文件内容的访问，buffer cache缓存文件的具体内容——物理磁盘上的磁盘块，这是加速对磁盘的访问。

#### Buffer cache（块缓存）

Buffer cache 也叫块缓冲，是对物理磁盘上的一个磁盘块进行的缓冲，其大小为通常为1k，磁盘块也是磁盘的组织单位。设立buffer cache的目的是为在程序多次访问同一磁盘块时，减少访问时间。系统将磁盘块首先读入buffer cache，如果cache空间不够时，会通过一定的策略将一些过时或多次未被访问的buffer cache清空。程序在下一次访问磁盘时首先查看是否在buffer cache找到所需块，命中可减少访问磁盘时间。不命中时需重新读入buffer cache。对buffer cache的写分为两种，一是直接写，这是程序在写buffer cache后也写磁盘，要读时从buffer cache上读，二是后台写，程序在写完buffer cache后并不立即写磁盘，因为有可能程序在很短时间内又需要写文件，如果直接写，就需多次写磁盘了。这样效率很低，而是过一段时间后由后台写，减少了多次访磁盘的时间。

Buffer cache是由物理内存分配，Linux系统为提高内存使用率，会将空闲内存全分给buffer cache ，当其他程序需要更多内存时，系统会减少cache大小。

#### Page cache和Buffer cache的区别

磁盘的操作有逻辑级（文件系统）和物理级（磁盘块），这两种Cache就是分别缓存逻辑和物理级数据的。

假设我们通过文件系统操作文件，那么文件将被缓存到Page Cache，如果需要刷新文件的时候，Page Cache将交给Buffer Cache去完成，因为Buffer Cache就是缓存磁盘块的。
也就是说，直接去操作文件，那就是Page Cache区缓存，用dd等命令直接操作磁盘块，就是Buffer Cache缓存的东西。
Page cache实际上是针对文件系统的，是文件的缓存，在文件层面上的数据会缓存到page cache。文件的逻辑层需要映射到实际的物理磁盘，这种映射关系由文件系统来完成。当page cache的数据需要刷新时，page cache中的数据交给buffer cache，但是这种处理在2.6版本的内核之后就变的很简单了，没有真正意义上的cache操作。
Buffer cache是针对磁盘块的缓存，也就是在没有文件系统的情况下，直接对磁盘进行操作的数据会缓存到buffer cache中，例如，文件系统的元数据都会缓存到buffer cache中。
简单说来，page cache用来缓存文件数据，buffer cache用来缓存磁盘数据。在有文件系统的情况下，对文件操作，那么数据会缓存到page cache，如果直接采用dd等工具对磁盘进行读写，那么数据会缓存到buffer cache。
Buffer(Buffer Cache)以块形式缓冲了块设备的操作，定时或手动的同步到硬盘，它是为了缓冲写操作然后一次性将很多改动写入硬盘，避免频繁写硬盘，提高写入效率。
Cache(Page Cache)以页面形式缓存了文件系统的文件，给需要使用的程序读取，它是为了给读操作提供缓冲，避免频繁读硬盘，提高读取效率。

### readahead

[readahead](./readahead.md)
