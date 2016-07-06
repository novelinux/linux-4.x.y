struct elf64_phdr
========================================

path: include/uapi/linux/elf.h
```
typedef struct elf64_phdr {
  Elf64_Word  p_type;
  Elf64_Word  p_flags;
  Elf64_Off   p_offset;        /* Segment file offset */
  Elf64_Addr  p_vaddr;         /* Segment virtual address */
  Elf64_Addr  p_paddr;         /* Segment physical address */
  Elf64_Xword p_filesz;        /* Segment size in file */
  Elf64_Xword p_memsz;         /* Segment size in memory */
  Elf64_Xword p_align;         /* Segment alignment, file & memory */
} Elf64_Phdr;
```

struct elf32_phdr
----------------------------------------

https://github.com/novelinux/linux-4.x.y/blob/master/include/uapi/linux/struct_elf32_phdr.md
