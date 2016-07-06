struct elf32_shdr
========================================

sh_name
----------------------------------------

path: include/uapi/linux/elf.h
```
typedef struct elf32_shdr {
  Elf32_Word    sh_name;
```

sh_name指定了节的名称。其值不是字符串本身，而是字符串表的一个索引。

sh_type
----------------------------------------

```
  Elf32_Word    sh_type;
```

sh_type指定了节的类型。有下列类型可用。

https://github.com/novelinux/linux-4.x.y/tree/master/include/uapi/linux/elf.h/sh_type.md

sh_flags
----------------------------------------

```
  Elf32_Word    sh_flags;
```

表示以下语义：

https://github.com/novelinux/linux-4.x.y/tree/master/include/uapi/linux/elf.h/sh_flags.md

sh_addr
----------------------------------------

```
  Elf32_Addr    sh_addr;
```

sh_addr指定节映射到虚拟地址空间中的位置。

sh_offset
----------------------------------------

```
  Elf32_Off     sh_offset;
```

sh_offset指定了节在文件中开始的位置。

sh_size
----------------------------------------

```
  Elf32_Word    sh_size;
```

sh_size指定了节的长度，单位为字节。

sh_link
----------------------------------------

```
  Elf32_Word    sh_link;
```

sh_link引用另一个节头表项，可能根据节类型而进行不同的解释。

sh_info
----------------------------------------

```
  Elf32_Word    sh_info;
```

sh_info与sh_link联用

**Notes**:

根据节类型不同，sh_link和sh_info的用法也具有不同的语义，如下所述:
* SHT_DYMAMIC类型的节使用sh_link指向节数据所用的字符串表。
  这种情况下不使用sh_info，设置为0。
* SHT_HASH类型的节使用sh_link指向所散列的符号表。sh_info不使用。
* SHT_REL和SHT_RELA的重定位节，使用sh_link指向相关的符号表。
  sh_info保存的是节头表中的索引，表示对哪个节进行重定位。
* SHT_SYMTAB和SHT_DYNSYM，sh_link指定了用作符号表的字符串表.
  STB_LOCAL类型,sh_info表示符号表中紧随最后一个局部符号之后的索引位置.

sh_addralign
----------------------------------------

```
  Elf32_Word    sh_addralign;
```

sh_addralign指定了节数据在内存中对齐的方式。

sh_entsize
----------------------------------------

```
  Elf32_Word    sh_entsize;
} Elf32_Shdr;
```

sh_entsize指定了节中各数据项的长度，前提是这些数据项的长度都相同，例如字符串表。

Samples
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/samples/fs/test_elf/README.md
