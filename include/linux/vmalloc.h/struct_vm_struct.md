struct vm_struct
========================================

内核在管理虚拟内存中的vmalloc区域时，内核必须跟踪哪些子区域被使用、哪些是空闲的。为此定义了一个
数据结构，将所有使用的部分保存在一个链表中。

**注意**: 内核使用了一个重要的数据结构称之为vm_area_struct，以管理用户空间进程的虚拟地址空间内容。
尽管名称和目的都是类似的，但不能混淆这两个结构。

next
----------------------------------------

path: include/linux/vmalloc.h
```
struct vm_struct {
    struct vm_struct    *next;
```

next使得内核可以将vmalloc区域中的所有子区域保存在一个单链表上。

addr
----------------------------------------

```
    void                *addr;
```

addr定义了分配的子区域在虚拟地址空间中的起始地址。

size
----------------------------------------

```
    unsigned long        size;
```

size表示该子区域的长度。可以根据该信息来勾画出vmalloc区域的完整分配方案。

flags
----------------------------------------

```
    unsigned long        flags;
```

flags存储了与该内存区关联的标志集合，这几乎是不可避免的。

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/vmalloc.h/struct_vm_struct.flags.md

pages
----------------------------------------

```
    struct page        **pages;
```

pages是一个指针,指向page指针的数组.每个数组成员都表示一个映射到虚拟地址空间中的物理内存页的page实例.

nr_pages
----------------------------------------

```
    unsigned int         nr_pages;
```

nr_pages指定pages中数组项的数目，即涉及的内存页数目。

phys_addr
----------------------------------------

```
    phys_addr_t          phys_addr;
```

phys_addr仅当用ioremap映射了由物理地址描述的物理内存区域时才需要。该信息保存在phys_addr中。

caller
----------------------------------------

```
    const void          *caller;
};
```

下图给出了该结构使用方式的一个实例。其中依次映射了3个(假想的)物理内存页，在物理内存中的位置
分别是1 023、725和7 311。在虚拟的vmalloc区域中，内核将其看作起始于VMALLOC_START + 100的一个连续
内存区。

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/vmalloc.h/res/struct_vm_struct.jpg
