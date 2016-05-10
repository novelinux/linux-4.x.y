struct map_desc
========================================

path: arch/arm/include/asm/mach/map.h
```
struct map_desc {
    unsigned long virtual;
    unsigned long pfn;
    unsigned long length;
    unsigned int type;
};
```

* virtual: 记录了映射到的虚拟地址的开始。
* pfn: 指明了被映射的物理内存的起始页框。
* length: 指明了被映射的物理内存的大小,注意这里不是页框大小.
* type: 指明映射类型，MT_xxx，决定了相应映射页面的访问权限。