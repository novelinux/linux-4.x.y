binfmts.h
========================================

linux_binprm
----------------------------------------

path: include/uapi/linux/binfmts.h
```
/* sizeof(linux_binprm->buf) */
#define BINPRM_BUF_SIZE 128
```

path: include/linux/binfmts.h
```
/*
 * This structure is used to hold the arguments that are used when loading binaries.
 */
struct linux_binprm {
       char buf[BINPRM_BUF_SIZE];
#ifdef CONFIG_MMU
       struct vm_area_struct *vma;
       unsigned long vma_pages;
#else
# define MAX_ARG_PAGES  32
  struct page *page[MAX_ARG_PAGES];
#endif
        struct mm_struct *mm;
        unsigned long p; /* current top of mem */
        unsigned int
             cred_prepared:1, /* true if creds already prepared (multiple
                               * preps happen for interpreters) */
             cap_effective:1; /* true if has elevated effective capabilities,
                               * false if not; except for init which inherits
                               * its parent's caps anyway */
#ifdef __alpha__
       unsigned int taso:1;
#endif
        unsigned int recursion_depth;
        struct file * file;
        struct cred *cred;      /* new credentials */
        int unsafe;             /* how unsafe this exec is (mask of LSM_UNSAFE_*) */
        unsigned int per_clear; /* bits to clear in current->personality */
        int argc, envc;
        const char * filename;  /* Name of binary as seen by procps */
        const char * interp;    /* Name of the binary really executed. Most
                                 * of the time same as filename, but could be
                                 * different for binfmt_{misc,script} */
        unsigned interp_flags;
        unsigned interp_data;
        unsigned long loader, exec;
        char tcomm[TASK_COMM_LEN];
};
```

### buf

空间存储来自程序文件前128字节内容，这些内容包括了二进制文件的类型。

### vma vs vma_pages

vma指向新进程虚拟地址空间的一个区域, 该区域用作新进程的栈空间.
vma_pages通常是该区域的页数.

### mm

mm 指向新进程的虚拟地址空间.

### p

p为新程序标记内存的顶端边界，但是为栈在顶端边界预留NULL指针。
当更多的信息添加进来时P的值将向下更新。

### file

file指向进程的可执行文件.

### cred vs per_clear

cred是一个单独分配的struct cred类型的变量，该变量存储新程序的权能，
它们继承与调用execve()函数的进程，但是可以使用setuid/setgid更新
权能，由于setuid/setgid一些对安全性有害的特性，一些兼容性特性也
被禁止了。per_clear记录了current->personality中要被清除的比特。

### argc vs envc

argc和envc设置成参数个数和环境参数个数.

### filename

要执行的文件的名称.

### interp

要执行的文件的真实名称，通常和filename相同.

linux_binfmt
----------------------------------------

path: include/linux/binfmts.h
```
/*
 * This structure defines the functions that are used to load the binary formats that
 * linux accepts.
 */
struct linux_binfmt {
    struct list_head lh;
    struct module *module;
    int (*load_binary)(struct linux_binprm *);
    int (*load_shlib)(struct file *);
    int (*core_dump)(struct coredump_params *cprm);
    unsigned long min_coredump;    /* minimal dump size */
};
```

### load_binary

用于加载普通程序.

### load_shlib

用于加载共享库.

### core_dump

用于在程序错误的情况下输出内存转储. 该转储随后可以使用调试器gdb
进行分析，以便解决问题.

### min_coredump

是生成内存转储时，内存转储文件长度的下界(通常这是一个内存页的长度).
