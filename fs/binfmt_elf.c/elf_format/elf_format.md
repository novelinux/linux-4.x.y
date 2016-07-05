elf
========================================

布局和结构
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/fs/binfmt_elf_c/elf_format/res/elf.png

### 链接视图

首先左边部分，它是以链接视图来看待elf文件的，从左边可以看出，包含了一个ELF头部，
它描绘了整个文件的组织结构。它还包括很多节区（section）。这些节有的是系统定义好的，
有些是用户在文件在通过.section命令自定义的，链接器会将多个输入目标文件中的相同的节合并。
节区部分包含链接视图的大量信息：指令、数据、符号表、重定位信息等等。除此之外，还包含
程序头部表（可选）和节区 头部表，程序头部表，告诉系统如何创建进程映像。用来构造进程
映像的目标文件必须具有程序头部表，可重定位文件不需要这个表。而节区头部表
（Section Heade Table）包含了描述文件节区的信息，每个节区在表中都有一项，
每一项给出诸如节区名称、节区大小这类信息。用于链接的目标文件必须包含节区头部表，
其他目标文件可以有，也可以没有这个表。

**注意**: 尽管图中显示的各个组成部分是有顺序的，实际上除了ELF头部表以外，
其他节区和段都没有规定的顺序。

### 执行视图

右半图是以程序执行视图来看待的，与左边对应，多了一个段（segment）的概念，编译器在生成目标文件时，
通常使用从零开始的相对地址，而在链接过程中，链接器从一个指定的地址开始，根据输入目标文件的顺序，
以段（segment）为单位将它们拼装起来。其中每个段可以包括很多个节（section）。

数据类型
----------------------------------------

因为ELF是一个处理器和体系结构无关的格式，它不能依赖特定的字长和字序.

path: include/uapi/linux/elf.h
```
/* 32-bit ELF base types. */
typedef __u32    Elf32_Addr;
typedef __u16    Elf32_Half;
typedef __u32    Elf32_Off;
typedef __s32    Elf32_Sword;
typedef __u32    Elf32_Word;

/* 64-bit ELF base types. */
typedef __u64    Elf64_Addr;
typedef __u16    Elf64_Half;
typedef __s16    Elf64_SHalf;
typedef __u64    Elf64_Off;
typedef __s32    Elf64_Sword;
typedef __u32    Elf64_Word;
typedef __u64    Elf64_Xword;
typedef __s64    Elf64_Sxword;

...

#define EI_NIDENT 16
```

elf头部
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/fs/binfmt_elf_c/elf_format/elf_header.md

程序头表
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/fs/binfmt_elf_c/elf_format/programe_header.md

节头表
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/fs/binfmt_elf_c/elf_format/section_header.md