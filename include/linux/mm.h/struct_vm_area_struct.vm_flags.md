vm_flags
========================================

path: include/linux/mm.h
```
/* 如下标志分别指定了页的内容是否可以读，写，执行或者由几个进程共享 */
#define VM_READ        0x00000001    /* currently active flags */
#define VM_WRITE       0x00000002
#define VM_EXEC        0x00000004
#define VM_SHARED      0x00000008

/* 用于确定是否可以设置对应的VM_*标志。这是mprotecte系统调用需要的. */
/* mprotect() hardcodes VM_MAYREAD >> 4 == VM_READ, and so for r/w/x bits. */
#define VM_MAYREAD     0x00000010    /* limits for mprotect() etc */
#define VM_MAYWRITE    0x00000020
#define VM_MAYEXEC     0x00000040
#define VM_MAYSHARE    0x00000080

/* VM_GROWSDOWN和VM_GROWSUP表示一个区域是否可以向下或者向上扩展(到更低或者更高的虚拟地址).
 * 由于堆自下而上增长，其区域需要设置VM_GROWSUP. VM_GROWSDOWN对栈设置，改区域自顶向下增长.
 */
#define VM_GROWSDOWN   0x00000100    /* general info on the segment */
...
#ifndef VM_GROWSUP
# define VM_GROWSUP    VM_NONE
#endif
...
/* 如果区域从头到尾顺序读取，则设置VM_SEQ_READ. VM_RAND_READ指定了读取可能是随机的。
 * 这两个标志用于"提示"内存管理子系统和块设备层，以优化其性能，访问是顺序的，则启用
 * 页的预读.
 */
#define VM_SEQ_READ     0x00008000    /* App will access data sequentially */
#define VM_RAND_READ    0x00010000    /* App will not benefit from clustered reads */

/* 如果设置了VM_DONTCOPY, 则相关区域在fork系统调用执行时不复制. */
#define VM_DONTCOPY     0x00020000      /* Do not copy this vma on fork */
/* 禁止区域通过mremap系统调用扩展 */
#define VM_DONTEXPAND   0x00040000    /* Cannot expand with mremap() */
...
/* 指定区域是否被归入overcommit特性的计算中. 这些特性以多种方式限制内存分配. */
#define VM_ACCOUNT      0x00100000    /* Is a VM accounted object */
...
/* 如果区域是基于某些特定体系机构支持的巨型页，则设置下列标志 */
#define VM_HUGETLB      0x00400000    /* Huge TLB Page VM */
```
