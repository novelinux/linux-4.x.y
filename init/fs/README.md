文件系统初始化
========================================

rootfs是基于内存的文件系统，所有操作都在内存中完成；也没有实际的存储设备，所以不需要
设备驱动程序的参与。基于以上原因，linux在启动阶段使用rootfs文件系统，当磁盘驱动程序和
磁盘文件系统成功加载后，linux系统可能会将系统根目录从rootfs切换到磁盘文件系统。

Flow
----------------------------------------

```
start_kernel
 |
 +-> vfs_caches_init_early
 |
 +-> vfs_caches_init
```

### vfs_caches_init_early

https://github.com/novelinux/linux-4.x.y/blob/master/fs/dcache.c/vfs_caches_init_early.md

### vfs_caches_init

https://github.com/novelinux/linux-4.x.y/blob/master/fs/dcache.c/vfs_caches_init.md
