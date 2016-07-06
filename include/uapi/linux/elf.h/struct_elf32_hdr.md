struct elf32_hdr
========================================

e_ident
----------------------------------------

path: include/uapi/linux/elf.h
```
#define EI_NIDENT    16

typedef struct elf32_hdr{
  unsigned char e_ident[EI_NIDENT];
```

e_ident可容纳16个字节,这些字节在所有体系结构上都使用unsigned char数据类型表示.

https://github.com/novelinux/linux-4.x.y/tree/master/include/uapi/linux/elf.h/e_ident.md

e_type
----------------------------------------

```
  Elf32_Half    e_type;
```

e_type用于区分如下所示各种ELF格式文件类型:

https://github.com/novelinux/linux-4.x.y/tree/master/include/uapi/linux/elf.h/e_type.md

e_machine
----------------------------------------

```
  Elf32_Half    e_machine;
```

指定文件所需的体系结构,注意：每种体系结构都需要定义函数elf_check_arch,并
由内核的通用代码使用，来确保加载的ELF文件可以在相应的体系结构上正确运行.

e_version
----------------------------------------

```
  Elf32_Word    e_version;
```

保存了版本信息，用于区分不同的ELF变体，但目前改规范只定义了版本1,有EV_CURRENT表示.

e_entry
----------------------------------------

```
  Elf32_Addr    e_entry;  /* Entry point */
```

给出了文件在虚拟内存中的入口点。这是程序已经加载并映射到内存之后，执行开始的位置.

e_phoff
----------------------------------------

```
  Elf32_Off     e_phoff;
```

存储了程序头表在二进制文件中的偏移量。

e_shoff
----------------------------------------

```
  Elf32_Off     e_shoff;
```

保存了节头表所在的偏移量.

e_flags
----------------------------------------

```
  Elf32_Word    e_flags;
```

用于保存特定处理器的标志。当前内核不使用该数据.

e_ehsize
----------------------------------------

```
  Elf32_Half    e_ehsize;
```

指定了elf头的长度，单位为字节.

e_phentsize
----------------------------------------

```
  Elf32_Half    e_phentsize;
```

指定了程序头表中一项的长度，单位为字节.

e_phnum
----------------------------------------

```
  Elf32_Half    e_phnum;
```

指定了程序头表中的项的数目.

e_shentsize
----------------------------------------

```
  Elf32_Half    e_shentsize;
```

指定了节头表中一项的长度，单位为字节.

e_shnum
----------------------------------------

```
  Elf32_Half    e_shnum;
```

指定了节头表中项的数目.

e_shstrndx
----------------------------------------

```
  Elf32_Half    e_shstrndx;
} Elf32_Ehdr;
```

保存了包含各节名称的字符串表在节头表中的索引位置.

Samples
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/samples/fs/test_elf/README.md
