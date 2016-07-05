struct linux_binfmt
========================================

在Linux内核中，每种二进制格式都表示为下列数据结构:

每种二进制格式首先必须使用register_binfmt向内核注册.该函数的目的是
向一个链表增加一个新的二进制格式，该链表的表头是:

lh
----------------------------------------

path: include/linux/binfmts.h
```
/*
 * This structure defines the functions that are used to load the binary formats that
 * linux accepts.
 */
struct linux_binfmt {
    struct list_head lh;
```

module
----------------------------------------

```
    struct module *module;
```

load_binary
----------------------------------------

```
    int (*load_binary)(struct linux_binprm *);
```

用于加载普通程序.

load_shlib
----------------------------------------

```
    int (*load_shlib)(struct file *);
```

用于加载共享库.

core_dump
----------------------------------------

```
    int (*core_dump)(struct coredump_params *cprm);
```

用于在程序错误的情况下输出内存转储. 该转储随后可以使用调试器gdb进行分析，以便解决问题.

min_coredump
----------------------------------------

```
    unsigned long min_coredump;    /* minimal dump size */
};
```

是生成内存转储时，内存转储文件长度的下界(通常这是一个内存页的长度).
