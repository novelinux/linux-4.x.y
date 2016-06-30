struct linux_binprm
========================================

buf
----------------------------------------

path: include/linux/binfmts.h
```
/*
 * This structure is used to hold the arguments that are used when loading binaries.
 */
struct linux_binprm {
    char buf[BINPRM_BUF_SIZE];
```

空间存储来自程序文件前128字节内容，这些内容包括了二进制文件的类型。

vma, vma_pages
----------------------------------------

```
#ifdef CONFIG_MMU
    struct vm_area_struct *vma;
    unsigned long vma_pages;
#else
# define MAX_ARG_PAGES    32
    struct page *page[MAX_ARG_PAGES];
#endif
```

### vma

指向新进程虚拟地址空间的一个区域, 该区域用作新进程的栈空间.

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/mm_types.h/struct_vm_area_struct.md

### vma_pages

通常是该区域的页数.

mm
----------------------------------------

```
    struct mm_struct *mm;
```

mm 指向新进程的虚拟地址空间.

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/mm_types.h/struct_mm_struct.md

p
----------------------------------------

```
    unsigned long p; /* current top of mem */
```

p为新程序标记内存的顶端边界，但是为栈在顶端边界预留NULL指针。当更多的信息添加进来时P的值将向下更新。

cred_prepared, cap_effective
----------------------------------------

```
    unsigned int
        cred_prepared:1,/* true if creds already prepared (multiple
                 * preps happen for interpreters) */
        cap_effective:1;/* true if has elevated effective capabilities,
                 * false if not; except for init which inherits
                 * its parent's caps anyway */
```

taso
----------------------------------------

```
#ifdef __alpha__
    unsigned int taso:1;
#endif
```

recursion_depth
----------------------------------------

```
    unsigned int recursion_depth; /* only for search_binary_handler() */
```

file
----------------------------------------

```
    struct file * file;
```

file指向进程的可执行文件.

https://github.com/novelinux/linux-4.x.y/blob/master/include/linux/fs.h/struct_file.md

cred
----------------------------------------

```
    struct cred *cred;    /* new credentials */
```

cred是一个单独分配的struct cred类型的变量，该变量存储新程序的权能，它们继承与调用execve()
函数的进程，但是可以使用setuid/setgid更新权能，由于setuid/setgid一些对安全性有害的特性，
一些兼容性特性也被禁止了。

unsafe
----------------------------------------

```
    int unsafe;        /* how unsafe this exec is (mask of LSM_UNSAFE_*) */
```

per_clear
----------------------------------------

```
    unsigned int per_clear;    /* bits to clear in current->personality */
```

per_clear记录了current->personality中要被清除的比特。

argc, envc
----------------------------------------

```
    int argc, envc;
```

argc和envc设置成参数个数和环境参数个数.

filename
----------------------------------------

```
    const char * filename;    /* Name of binary as seen by procps */
```

要执行的文件的名称.

interp
----------------------------------------

```
    const char * interp;    /* Name of the binary really executed. Most
                   of the time same as filename, but could be
                   different for binfmt_{misc,script} */
```

要执行的文件的真实名称，通常和filename相同.

interp_flags
----------------------------------------

```
    unsigned interp_flags;
```

interp_data
----------------------------------------

```
    unsigned interp_data;
```

loader, exec
----------------------------------------

```
    unsigned long loader, exec;
};
```