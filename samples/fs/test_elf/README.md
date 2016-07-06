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

Program Header Table
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

Sections
----------------------------------------

```
$ arm-linux-androideabi-readelf -S elf
There are 33 section headers, starting at offset 0x1b18:

Section Headers:
  [Nr] Name              Type            Addr     Off    Size   ES Flg Lk Inf Al
  [ 0]                   NULL            00000000 000000 000000 00      0   0  0
  [ 1] .interp           PROGBITS        00000134 000134 000013 00   A  0   0  1
  [ 2] .dynsym           DYNSYM          00000148 000148 0000a0 10   A  3   1  4
  [ 3] .dynstr           STRTAB          000001e8 0001e8 000089 00   A  0   0  1
  [ 4] .hash             HASH            00000274 000274 00003c 04   A  2   0  4
  [ 5] .rel.dyn          REL             000002b0 0002b0 000020 08   A  2   0  4
  [ 6] .rel.plt          REL             000002d0 0002d0 000020 08   A  2   0  4
  [ 7] .plt              PROGBITS        000002f0 0002f0 000044 00  AX  0   0  4
  [ 8] .text             PROGBITS        00000334 000334 0000d4 00  AX  0   0  4
  [ 9] .note.android.ide PROGBITS        00000408 000408 000018 00   A  0   0  4
  [10] .ARM.extab        PROGBITS        00000420 000420 00000c 00   A  0   0  4
  [11] .ARM.exidx        ARM_EXIDX       0000042c 00042c 000010 08  AL  8   0  4
  [12] .rodata           PROGBITS        0000043c 00043c 000028 01 AMS  0   0  1
  [13] .preinit_array    PREINIT_ARRAY   00001ec4 000ec4 000008 00  WA  0   0  4
  [14] .init_array       INIT_ARRAY      00001ecc 000ecc 000008 00  WA  0   0  4
  [15] .fini_array       FINI_ARRAY      00001ed4 000ed4 000008 00  WA  0   0  4
  [16] .dynamic          DYNAMIC         00001edc 000edc 0000f8 08  WA  3   0  4
  [17] .got              PROGBITS        00001fd4 000fd4 00002c 00  WA  0   0  4
  [18] .bss              NOBITS          00002000 001000 000004 00  WA  0   0  4
  [19] .comment          PROGBITS        00000000 001000 000010 01  MS  0   0  1
  [20] .debug_info       PROGBITS        00000000 001010 0001bf 00      0   0  1
  [21] .debug_abbrev     PROGBITS        00000000 0011cf 000133 00      0   0  1
  [22] .debug_loc        PROGBITS        00000000 001302 0000be 00      0   0  1
  [23] .debug_aranges    PROGBITS        00000000 0013c0 000028 00      0   0  1
  [24] .debug_ranges     PROGBITS        00000000 0013e8 000030 00      0   0  1
  [25] .debug_line       PROGBITS        00000000 001418 000094 00      0   0  1
  [26] .debug_str        PROGBITS        00000000 0014ac 000126 01  MS  0   0  1
  [27] .debug_frame      PROGBITS        00000000 0015d4 000044 00      0   0  4
  [28] .note.gnu.gold-ve NOTE            00000000 001618 00001c 00      0   0  4
  [29] .ARM.attributes   ARM_ATTRIBUTES  00000000 001634 000036 00      0   0  1
  [30] .symtab           SYMTAB          00000000 00166c 000250 10     31  24  4
  [31] .strtab           STRTAB          00000000 0018bc 000107 00      0   0  1
  [32] .shstrtab         STRTAB          00000000 0019c3 000153 00      0   0  1
Key to Flags:
  W (write), A (alloc), X (execute), M (merge), S (strings)
  I (info), L (link order), G (group), T (TLS), E (exclude), x (unknown)
  O (extra OS processing required) o (OS specific), p (processor specific)
```

ELF标准定义了若干固定名称的节。这些用于执行大多数目标文件所需的标准任务。
所有名称都从点开始，以便与用户定义节或非标准节相区分。最重要的标准节如下所示。
* .bss保存程序未初始化的数据节，在程序开始运行前填充0字节。
* .data包含已经初始化的程序数据。例如，预先初始化的结构，
  其中在编译时填充了静态数据。这些数据可以在程序运行期间更改。
* .rodata保存了程序使用的只读数据，不能修改，例如字符串。
* .dynamic和.dynstr保存了动态信息。
* .interp保存了程序解释器的名称，形式为字符串。
* .shstrtab包含了一个字符串表，定义了节名称。
* .strtab保存了一个字符串表，主要包含了符号表需要的各个字符串。

**Notes**:
.strtab不是默认情况下ELF文件中唯一的字符串表。
.shstrtab用于存放文件中各个节的文本名称

* .symtab保存了二进制文件的符号表。
* .init和.fini保存了程序初始化和结束时执行的机器指令。
  这两个节的内容通常是由编译器及其辅助工具自动创建的，
  主要是为程序建立一个适当的运行时环境。
* .text保存了主要的机器指令。

Symbol Table
----------------------------------------

符号表是每个ELF文件的一个重要部分，因为它保存了程序实现或使用的
所有（全局）变量和函数。如果程序引用了一个自身代码未定义的符号，
则称之为未定义符号（例如，例子中的printf函数，就是定义在C标准库中）。
此类引用必须在静态链接期间用其他目标模块或库解决，或在加载时间通过
动态链接（使用linker）解决。

nm工具可生成程序定义和使用的所有符号列表，如下所示：

```
$ arm-linux-androideabi-nm elf
00000408 r abitag
         U __aeabi_unwind_cpp_pr0
         U __aeabi_unwind_cpp_pr1
000003ac t atexit
00002000 A __bss_start
         U __cxa_atexit
00002000 b __dso_handle
00001edc d _DYNAMIC
00002000 A _edata
00002004 A _end
00001ed4 T __FINI_ARRAY__
00001fe4 d _GLOBAL_OFFSET_TABLE_
00001ecc T __INIT_ARRAY__
         U __libc_init
000003e8 T main
00001ec4 D __PREINIT_ARRAY__
         U printf
         U puts
00000334 t _start
```

ELF是如何实现符号表机制的？以下3个节用于容纳相关的数据。
* .symtab确定符号的名称与其值之间的关联。但符号的名称不是
  直接以字符串形式出现的，而是表示为某个字符串数组的索引。
* .strtab保存了字符串数组。
* .hash保存了一个散列表，以帮助快速查找符号。
* .symtab节中的每一项由两个元素组成，符号名在字符串表中的位置和符号的值。