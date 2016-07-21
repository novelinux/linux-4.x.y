Block Device
========================================

块设备有一组属性，由内核管理。内核使用所谓的请求队列管理（request queue management），
使得此类与设备的通信尽可能高效。它能够缓存并重排读写数据块的请求。请求的结果也同样保存
在缓存中，使得可以用非常高效的方式读取/重新读取数据。在进程重复访问文件的同一部分时，或
不同进程并行访问同一数据时，该特性尤其有用。完成这些任务需要很多数据结构，如下所述,
概述了块设备层的各个成员。

https://github.com/novelinux/linux-4.x.y/tree/master/fs/block_dev.c/vfs_bd.jpg

Data Structure
----------------------------------------

### struct block_device

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/fs.h/struct_block_device.md
