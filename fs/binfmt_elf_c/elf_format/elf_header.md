elf header
========================================

Sources
----------------------------------------

以32位体系结构elf header来说明.

path: include/uapi/linux/elf.h
```
typedef struct elf32_hdr{
  unsigned char e_ident[EI_NIDENT];
  Elf32_Half    e_type;
  Elf32_Half    e_machine;
  Elf32_Word    e_version;
  Elf32_Addr    e_entry;  /* Entry point */
  Elf32_Off     e_phoff;
  Elf32_Off     e_shoff;
  Elf32_Word    e_flags;
  Elf32_Half    e_ehsize;
  Elf32_Half    e_phentsize;
  Elf32_Half    e_phnum;
  Elf32_Half    e_shentsize;
  Elf32_Half    e_shnum;
  Elf32_Half    e_shstrndx;
} Elf32_Ehdr;

typedef struct elf64_hdr {
  unsigned char e_ident[EI_NIDENT];    /* ELF "magic number" */
  Elf64_Half    e_type;
  Elf64_Half    e_machine;
  Elf64_Word    e_version;
  Elf64_Addr    e_entry;        /* Entry point virtual address */
  Elf64_Off     e_phoff;        /* Program header table file offset */
  Elf64_Off     e_shoff;        /* Section header table file offset */
  Elf64_Word    e_flags;
  Elf64_Half    e_ehsize;
  Elf64_Half    e_phentsize;
  Elf64_Half    e_phnum;
  Elf64_Half    e_shentsize;
  Elf64_Half    e_shnum;
  Elf64_Half    e_shstrndx;
} Elf64_Ehdr;
```

### e_ident

#### EI_MAG(n)

e_ident可容纳16个字节,这些字节在所有体系结构上都使用unsigned char数据类型表示.
前四个字节包含了0x7f和字母E(0x45), L(0x4c), F(0x46). 对应magic值定义如下:

path: include/uapi/linux/elf.h
```
#define    EI_MAG0        0        /* e_ident[] indexes */
#define    EI_MAG1        1
#define    EI_MAG2        2
#define    EI_MAG3        3
...
#define    ELFMAG0        0x7f        /* EI_MAG */
#define    ELFMAG1        'E'
#define    ELFMAG2        'L'
#define    ELFMAG3        'F'
#define    ELFMAG         "\177ELF"
```

其它的字节位置都有特定的含义.如下所示:

path: include/uapi/linux/elf.h
```
...
#define    EI_CLASS       4
#define    EI_DATA        5
#define    EI_VERSION     6
#define    EI_OSABI       7
#define    EI_PAD         8
```

#### EI_CLASS

用于标识文件类别,将文件分为32位和64位两类.定义的值如下所示:

path: include/uapi/linux/elf.h
```
#define    ELFCLASSNONE    0        /* EI_CLASS */
#define    ELFCLASS32      1
#define    ELFCLASS64      2
#define    ELFCLASSNUM     3
```

#### EI_DATA

用于标识指定ELF文件格式使用的字节序列.定义值如下所示:

path: include/uapi/linux/elf.h
```
#define ELFDATANONE    0        /* e_ident[EI_DATA] */
#define ELFDATA2LSB    1
#define ELFDATA2MSB    2
```

#### EI_VERSION

用于表示ELF头的文件版本,当前只允许使用EV_CURRENT,这是第一个版本.

path: include/uapi/linux/elf.h
```
#define EV_NONE        0        /* e_version, EI_VERSION */
#define EV_CURRENT     1
#define EV_NUM         2
```

#### EI_OSABI

用于标注文件用于的操作系统.

path: include/uapi/linux/elf.h
```
#define ELFOSABI_NONE  0
#define ELFOSABI_LINUX 3
```

#### EI_PAD

从这个字节起, ELF头标识的剩余的字节使用0填充,因为这些位置尚不需要.

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