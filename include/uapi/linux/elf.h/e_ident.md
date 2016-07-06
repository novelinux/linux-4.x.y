e_ident
========================================

EI_MAG
----------------------------------------

前四个字节包含了0x7f和字母E(0x45), L(0x4c), F(0x46). 对应magic值定义如下:

path: include/uapi/linux/elf.h
```
#define    EI_MAG0        0        /* e_ident[] indexes */
#define    EI_MAG1        1
#define    EI_MAG2        2
#define    EI_MAG3        3
```

### ELFMAG

path: include/uapi/linux/elf.h
```
#define    ELFMAG0        0x7f        /* EI_MAG */
#define    ELFMAG1        'E'
#define    ELFMAG2        'L'
#define    ELFMAG3        'F'
#define    ELFMAG         "\177ELF"
```

EI_CLASS
----------------------------------------

用于标识文件类别,将文件分为32位和64位两类.定义的值如下所示:

path: include/uapi/linux/elf.h
```
#define    EI_CLASS       4
```

### ELFCLASS

path: include/uapi/linux/elf.h
```
#define    ELFCLASSNONE    0        /* EI_CLASS */
#define    ELFCLASS32      1
#define    ELFCLASS64      2
#define    ELFCLASSNUM     3
```

EI_DATA
----------------------------------------

用于标识指定ELF文件格式使用的字节序列.定义值如下所示:

path: include/uapi/linux/elf.h
```
#define    EI_DATA        5
```

### ELFDATA

path: include/uapi/linux/elf.h
```
#define ELFDATANONE    0        /* e_ident[EI_DATA] */
#define ELFDATA2LSB    1
#define ELFDATA2MSB    2
```

EI_VERSION
----------------------------------------

用于表示ELF头的文件版本,当前只允许使用EV_CURRENT,这是第一个版本.

path: include/uapi/linux/elf.h
```
#define    EI_VERSION     6
```

### EV

path: include/uapi/linux/elf.h
```
#define EV_NONE        0        /* e_version, EI_VERSION */
#define EV_CURRENT     1
#define EV_NUM         2
```

EI_OSABI
----------------------------------------

用于标注文件用于的操作系统.

path: include/uapi/linux/elf.h
```
#define    EI_OSABI       7
```

### ELFOSABI

path: include/uapi/linux/elf.h
```
#define ELFOSABI_NONE  0
#define ELFOSABI_LINUX 3

EI_PAD
----------------------------------------

从这个字节起, ELF头标识的剩余的字节使用0填充,因为这些位置尚不需要.

path: include/uapi/linux/elf.h
```
#define    EI_PAD         8
```
