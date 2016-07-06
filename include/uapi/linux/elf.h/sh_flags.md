sh_flags
========================================

path: include/uapi/linux/elf.h
```
/* sh_flags */
#define SHF_WRITE	0x1 // 节是否可写
#define SHF_ALLOC	0x2 // 是否将为其分配虚拟内存
#define SHF_EXECINSTR	0x4 // 节是否包含可执行的机器代码
#define SHF_MASKPROC	0xf0000000
```