__initdata_memblock
========================================

path: include/linux/memblock.h
```
#ifdef CONFIG_ARCH_DISCARD_MEMBLOCK
#define __init_memblock __meminit
#define __initdata_memblock __meminitdata
#else
#define __init_memblock
#define __initdata_memblock
#endif
```

如果启用CONFIG_ARCH_DISCARD_MEMBLOCK宏配置选项，memblock代码会被放到.init代码段，在内核
启动完成后 memblock 代码会从.init代码段释放。
