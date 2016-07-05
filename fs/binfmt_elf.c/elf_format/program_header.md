program header
========================================

程序头表(目标文件没有改表).

Source
----------------------------------------

path: include/uapi/linux/elf.h
```
typedef struct elf32_phdr{
  Elf32_Word    p_type;
  Elf32_Off     p_offset;
  Elf32_Addr    p_vaddr;
  Elf32_Addr    p_paddr;
  Elf32_Word    p_filesz;
  Elf32_Word    p_memsz;
  Elf32_Word    p_flags;
  Elf32_Word    p_align;
} Elf32_Phdr;

typedef struct elf64_phdr {
  Elf64_Word  p_type;
  Elf64_Word  p_flags;
  Elf64_Off   p_offset;        /* Segment file offset */
  Elf64_Addr  p_vaddr;         /* Segment virtual address */
  Elf64_Addr  p_paddr;         /* Segment physical address */
  Elf64_Xword p_filesz;        /* Segment size in file */
  Elf64_Xword p_memsz;         /* Segment size in memory */
  Elf64_Xword p_align;         /* Segment alignment, file & memory */
} Elf64_Phdr;
```

### p_type

表示当前项描述符的段的种类.

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

### p_offset

给出了所描述段在文件中的偏移量（从二进制文件起始处开始计算，单位为字节）.

### p_vaddr

给出了段的数据映射到虚拟地址空间中的位置(对PT_LOAD类型的段).

### p_paddr

只支持物理寻址，不支持虚拟寻址的系统，将使用p_paddr保存的信息.

### p_filesz

指定段在二进制文件中的长度(单位为字节).

### p_memsz

指定段在虚拟地址空间的长度(单位为字节). 与文件中物理的长度差值可通过截断数据
或填充0字节来补偿.

### p_flags

保存了标志信息，定义了改段的访问权限.

```
/* These constants define the permissions on sections in the program
   header, p_flags. */
#define PF_R        0x4 /* 读 */
#define PF_W        0x2 /* 写 */
#define PF_X        0x1 /* 可执行 */
```

### p_align

指定了段在内存和二进制文件中的对齐方式(p_vaddr和p_offset地址必须是p_align的).

Example
----------------------------------------

path: src/elf

### arm-linux-androideabi-readelf

```
$ arm-linux-androideabi-readelf -l elf

Elf file type is DYN (Shared object file)
Entry point 0x334
There are 8 program headers, starting at offset 52

Program Headers:
  Type           Offset   VirtAddr   PhysAddr   FileSiz MemSiz  Flg Align
  PHDR           0x000034 0x00000034 0x00000034 0x00100 0x00100 R   0x4
  INTERP         0x000134 0x00000134 0x00000134 0x00013 0x00013 R   0x1
      [Requesting program interpreter: /system/bin/linker]
  LOAD           0x000000 0x00000000 0x00000000 0x00464 0x00464 R E 0x1000
  LOAD           0x000ec4 0x00001ec4 0x00001ec4 0x0013c 0x00140 RW  0x1000
  DYNAMIC        0x000edc 0x00001edc 0x00001edc 0x000f8 0x000f8 RW  0x4
  GNU_STACK      0x000000 0x00000000 0x00000000 0x00000 0x00000 RW  0
  EXIDX          0x00042c 0x0000042c 0x0000042c 0x00010 0x00010 R   0x4
  GNU_RELRO      0x000ec4 0x00001ec4 0x00001ec4 0x0013c 0x0013c RW  0x4

 Section to Segment mapping:
  Segment Sections...
   00
   01     .interp
   02     .interp .dynsym .dynstr .hash .rel.dyn .rel.plt .plt .text .note.android.ident .ARM.extab .ARM.exidx .rodata
   03     .preinit_array .init_array .fini_array .dynamic .got .bss
   04     .dynamic
   05
   06     .ARM.exidx
   07     .preinit_array .init_array .fini_array .dynamic .got
```

#### PHDR

保存程序头表.

#### INTERP

用于指定在程序已经从可执行文件映射到内存之后，必须调用的解释器. 在这里解释器指的是这样
一个程序: 通过链接其它库，来满足为解决的引用. 在这里/system/bin/linker用于在虚拟地址空间
中插入程序运行所需的动态库.

#### LOAD

表示一个需要从二进制文件映射到虚拟地址空间的段. 其中保存了常量数据(如字符串),程序
的目标代码.

#### DYNAMIC

保存了由动态链接器使用的信息.

#### NOTE

保存了专有信息.

#### GNU_STACK

用于描述当前堆栈段的保护权限.

```
/* Stack area protections */
#define EXSTACK_DEFAULT   0    /* Whatever the arch defaults to */
#define EXSTACK_DISABLE_X 1    /* Disable executable stacks */
#define EXSTACK_ENABLE_X  2    /* Enable executable stacks */
```