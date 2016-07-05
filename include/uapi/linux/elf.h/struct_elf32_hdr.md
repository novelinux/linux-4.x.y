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

```
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
```
