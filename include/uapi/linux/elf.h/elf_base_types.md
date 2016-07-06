ELF base types
========================================

因为ELF是一个处理器和体系结构无关的格式，它不能依赖特定的字长或
字节序（小端序或大端序），至少对文件中那些需要在所有系统上读取和
理解的数据元素来说，是这样。出现在.text段中的机器代码，存储为宿主
系统的表示形式，以避免笨拙的转换操作。为此内核定义了一些数据类型，
在所有体系结构上具有相同的位宽，如下所示：

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
```