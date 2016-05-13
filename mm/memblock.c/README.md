Memblock
========================================

在启动过程期间，尽管内存管理尚未初始化，但内核仍然需要分配内存以创建各种数据结构。
Memblock 是在早期引导过程中管理内存的方法之一，此时内核内存分配器还没运行。Memblock
以前被定义为Logical Memory Block(逻辑内存块), 但根据Yinghai Lu 的补丁, 它被重命名为memblock。
ARM架构的linux内核就采用了这种方法。现在我们将进一步了解memblock是如何实现的。

Data Structure
----------------------------------------

### struct memblock

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/memblock.h/struct_memblock.md

### struct memblock_type

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/memblock.h/struct_memblock_type.md

### struct memblock_region

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/memblock.h/struct_memblock_region.md

以上结构体之间的关系如下所示:

```
+---------------------------+   +---------------------------+
|         memblock          |   |                           |
|  _______________________  |   |                           |
| |        memory         | |   |       Array of the        |
| |      memblock_type    |-|-->|      membock_region       |
| |_______________________| |   |                           |
|                           |   +---------------------------+
|  _______________________  |   +---------------------------+
| |       reserved        | |   |                           |
| |      memblock_type    |-|-->|       Array of the        |
| |_______________________| |   |      memblock_region      |
|                           |   |                           |
+---------------------------+   +---------------------------+
```

Initialization
----------------------------------------

结构体memblock的初始化变量名和结构体名相同是memblock.

https://github.com/novelinux/linux-4.x.y/tree/master/mm/memblock.c/memblock.md

#### ARM - arm_memblock_init:

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/mm/init.c/arm_memblock_init.md

APIS
----------------------------------------

#### memblock_add_range

https://github.com/novelinux/linux-4.x.y/tree/master/mm/memblock.c/memblock_add_range.md

debug
----------------------------------------

向内核参数传入: "memblock=debug"即可打印对应的memblock信息.
