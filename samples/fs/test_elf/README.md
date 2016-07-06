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

### file

使用file查看刚生成的elf可执行文件:

```
$ file elf
elf: ELF 32-bit LSB  shared object, ARM, EABI5 version 1 (SYSV), dynamically linked (uses shared libs), not stripped
```

### arm-linux-androideabi-readelf

```
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