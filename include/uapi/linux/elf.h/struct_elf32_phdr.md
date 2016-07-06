struct elf32_phdr
========================================

p_type
----------------------------------------

path: include/uapi/linux/elf.h
```
typedef struct elf32_phdr{
  Elf32_Word    p_type;
```

表示当前项描述符的段的种类.

https://github.com/novelinux/linux-4.x.y/tree/master/include/uapi/linux/elf.h/p_type.md

p_offset
----------------------------------------

```
  Elf32_Off     p_offset;
```

给出了所描述段在文件中的偏移量（从二进制文件起始处开始计算，单位为字节）.

p_vaddr
----------------------------------------

```
  Elf32_Addr    p_vaddr;
```

给出了段的数据映射到虚拟地址空间中的位置(对PT_LOAD类型的段).

p_paddr
----------------------------------------

```
  Elf32_Addr    p_paddr;
```

只支持物理寻址，不支持虚拟寻址的系统，将使用p_paddr保存的信息.

p_filesz
----------------------------------------

```
  Elf32_Word    p_filesz;
```

指定段在二进制文件中的长度(单位为字节).

p_memsz
----------------------------------------

```
  Elf32_Word    p_memsz;
```

指定段在虚拟地址空间的长度(单位为字节). 与文件中物理的长度差值
可通过截断数据或填充0字节来补偿.

p_flags
----------------------------------------

```
  Elf32_Word    p_flags;
```

保存了标志信息，定义了改段的访问权限.

p_align
----------------------------------------

```
  Elf32_Word    p_align;
} Elf32_Phdr;
```

指定了段在内存和二进制文件中的对齐方式(p_vaddr和p_offset地址必须是p_align的).

Samples
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/samples/fs/test_elf/README.md
