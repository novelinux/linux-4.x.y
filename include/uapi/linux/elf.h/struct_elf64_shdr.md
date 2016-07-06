struct elf64_shdr
========================================

path: include/uapi/linux/elf.h
```
typedef struct elf64_shdr {
  Elf64_Word sh_name;        /* Section name, index in string tbl */
  Elf64_Word sh_type;        /* Type of section */
  Elf64_Xword sh_flags;        /* Miscellaneous section attributes */
  Elf64_Addr sh_addr;        /* Section virtual addr at execution */
  Elf64_Off sh_offset;        /* Section file offset */
  Elf64_Xword sh_size;        /* Size of section in bytes */
  Elf64_Word sh_link;        /* Index of another section */
  Elf64_Word sh_info;        /* Additional section information */
  Elf64_Xword sh_addralign;    /* Section alignment */
  Elf64_Xword sh_entsize;    /* Entry size if section holds table */
} Elf64_Shdr;
```

struct elf32_shdr
----------------------------------------

https://github.com/novelinux/linux-4.x.y/blob/master/include/uapi/linux/struct_elf32_shdr.md
