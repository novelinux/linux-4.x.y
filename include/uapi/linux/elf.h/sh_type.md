sh_type
========================================

path: include/uapi/linux/elf.h
```
/* sh_type */
#define SHT_NULL      0 // SH_NULL表示该节不使用。其数据将忽略。
#define SHT_PROGBITS  1 // 保存程序相关信息，其格式是不定义的，与这里的讨论无关。
#define SHT_SYMTAB    2 // 保存一个符号表
#define SHT_STRTAB    3 // 表示一个包含字符串表的节。
#define SHT_RELA      4 // SH_RELA保存重定位信息
#define SHT_HASH      5 // 定义了一个节，其中保存了一个散列表，使得符号表中的项可以更快速地查找
#define SHT_DYNAMIC   6 // 保存了关于动态链接的信息
#define SHT_NOTE      7
#define SHT_NOBITS    8
#define SHT_REL       9
#define SHT_SHLIB     10
#define SHT_DYNSYM    11 // 也保存一个符号表
#define SHT_NUM       12
#define SHT_LOPROC    0x70000000
#define SHT_HIPROC    0x7fffffff
#define SHT_LOUSER    0x80000000
#define SHT_HIUSER    0xffffffff
```