elf
========================================

SOURCES
----------------------------------------

path: elf.c
```
#include <stdio.h>

int add (int a, int b)
{
    printf("Numbers are added together.\n");
    return a + b;
}

int main(int argc, char *argv[])
{
    int a, b, ret;

    a = 3;
    b = 4;

    ret = add(a, b);
    printf("Result: %d\n", ret);

    return 0;
}
```

ELF HEADER
----------------------------------------

```
$ file elf
elf: ELF 32-bit LSB  shared object, ARM, EABI5 version 1 (SYSV), dynamically linked (uses shared libs), not stripped
$ arm-linux-androideabi-readelf -h elf
ELF Header:
  Magic:   7f 45 4c 46 01 01 01 00 00 00 00 00 00 00 00 00
  Class:                             ELF32
  Data:                              2's complement, little endian
  Version:                           1 (current)
  OS/ABI:                            UNIX - System V
  ABI Version:                       0
  Type:                              DYN (Shared object file)
  Machine:                           ARM
  Version:                           0x1
  Entry point address:               0x334
  Start of program headers:          52 (bytes into file)
  Start of section headers:          6936 (bytes into file)
  Flags:                             0x5000000, Version5 EABI
  Size of this header:               52 (bytes)
  Size of program headers:           32 (bytes)
  Number of program headers:         8
  Size of section headers:           40 (bytes)
  Number of section headers:         33
  Section header string table index: 32
```

Program HEADER
----------------------------------------

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

### PHDR

保存程序头表.

### INTERP

用于指定在程序已经从可执行文件映射到内存之后，必须调用的解释器.
在这里解释器指的是这样一个程序: 通过链接其它库，来满足为解决的引用.
在这里/system/bin/linker用于在虚拟地址空间中插入程序运行所需的动态库.

### LOAD

表示一个需要从二进制文件映射到虚拟地址空间的段.
其中保存了常量数据(如字符串),程序的目标代码.

### DYNAMIC

保存了由动态链接器使用的信息.

### NOTE

保存了专有信息.

### GNU_STACK

用于描述当前堆栈段的保护权限.

```
/* Stack area protections */
#define EXSTACK_DEFAULT   0    /* Whatever the arch defaults to */
#define EXSTACK_DISABLE_X 1    /* Disable executable stacks */
#define EXSTACK_ENABLE_X  2    /* Enable executable stacks */
```
