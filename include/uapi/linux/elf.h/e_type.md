e_type
========================================

path: include/uapi/linux/elf.h
```
/* These constants define the different elf file types */
#define ET_NONE   0
#define ET_REL    1 /* object file */
#define ET_EXEC   2 /* executable file */
#define ET_DYN    3 /* dynamic library */
#define ET_CORE   4 /* core dump */
#define ET_LOPROC 0xff00
#define ET_HIPROC 0xffff
```
