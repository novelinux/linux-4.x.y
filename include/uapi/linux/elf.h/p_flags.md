p_flags
========================================

path: include/uapi/linux/elf.h
```
/* These constants define the permissions on sections in the program
   header, p_flags. */
#define PF_R        0x4 /* 读 */
#define PF_W        0x2 /* 写 */
#define PF_X        0x1 /* 可执行 */
```