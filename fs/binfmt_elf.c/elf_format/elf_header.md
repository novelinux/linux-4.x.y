elf header
========================================

### e_type

e_type用于区分如下所示各种ELF格式文件类型:

path: include/uapi/linux/elf.h
```
/* These constants define the different elf file types */
...
#define ET_REL    1 /* object file */
#define ET_EXEC   2 /* executable file */
#define ET_DYN    3 /* dynamic library */
#define ET_CORE   4 /* core dump */
...
```

### e_machine

指定文件所需的体系结构,注意：每种体系结构都需要定义函数elf_check_arch,并
由内核的通用代码使用，来确保加载的ELF文件可以在相应的体系结构上正确运行.

### e_version

保存了版本信息，用于区分不同的ELF变体，但目前改规范只定义了版本1,有EV_CURRENT表示.

### e_entry

给出了文件在虚拟内存中的入口点。这是程序已经加载并映射到内存之后，执行开始的位置.

### e_phoff

存储了程序投标在二进制文件中的偏移量.

### e_shoff

保存了节头表所在的偏移量.

### e_flags

用于保存特定处理器的标志。当前内核不使用该数据.

### e_ehsize

指定了elf头的长度，单位为字节.

### e_phentsize

指定了程序头表中一项的长度，单位为字节.

### e_phnum

指定了程序头表中的项的数目.

### e_shentsize

指定了节头表中一项的长度，单位为字节.

### e_shnum

指定了节头表中项的数目.

### e_shstrndx

保存了包含各节名称的字符串表在节头表中的索引位置.

Example
----------------------------------------

path: src/elf

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