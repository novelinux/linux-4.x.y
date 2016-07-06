p_type
========================================

path: include/uapi/linux/elf.h
```
/* These constants are for the segment types stored in the image headers */
#define PT_NULL    0
#define PT_LOAD    1  /* 表示可装载段，在程序执行前从二进制文件映射到内存 */
#define PT_DYNAMIC 2  /* 段包含了用于动态链接器的信息 */
#define PT_INTERP  3  /* 表示当前段指定了用于动态链接器的程序解释器 */
#define PT_NOTE    4  /* 指定了一个段，其中可能包含专有的编译器信息 */
#define PT_SHLIB   5  /* 此段类型被保留，不过语义未指定。包含这种类型的段的程序与 ABI不符。*/
/* 给出了程序头部表自身的大小和位置，既包括在文件中也包括在内存中的信息。
 * 此类型的段在文件中不能出现一次以上。并且只有程序头部表是程序的内存映像
 * 的一部分时才起作用。如果存在此类型段，则必须在所有可加载段项目的前面。
 */
#define PT_PHDR    6
#define PT_TLS     7               /* Thread local storage segment */
#define PT_LOOS    0x60000000      /* OS-specific */
#define PT_HIOS    0x6fffffff      /* OS-specific */
/* 此范围PT_LOPROC~PT_HIPROC的类型保留给处理器专用语义 */
#define PT_LOPROC  0x70000000
#define PT_HIPROC  0x7fffffff
#define PT_GNU_EH_FRAME        0x6474e550

#define PT_GNU_STACK    (PT_LOOS + 0x474e551)
```