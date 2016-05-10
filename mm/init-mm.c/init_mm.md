init_mm
========================================

任何一个用户进程都有自己的页表，与此同时，内核本身就是一个名为init_task的0号进程，每一个进程
都有一个mm_struct结构管理进程的内存空间，init_mm是内核的mm_struct。在系统引导阶段，首先通过
__create_page_tables在内核代码的起始处_stext向低地址方向预留16K，用于一级页表(主内存页表)的存放，
每个进程的页表都通过mm_struct中的pgd描述符进行引用。内核页表被定义在swapper_pg_dir。

path: mm/init-mm.c
```
struct mm_struct init_mm = {
    .mm_rb       = RB_ROOT,
    .pgd         = swapper_pg_dir,
    .mm_users    = ATOMIC_INIT(2),
    .mm_count    = ATOMIC_INIT(1),
    .mmap_sem    = __RWSEM_INITIALIZER(init_mm.mmap_sem),
    .page_table_lock =  __SPIN_LOCK_UNLOCKED(init_mm.page_table_lock),
    .mmlist        = LIST_HEAD_INIT(init_mm.mmlist),
    INIT_MM_CONTEXT(init_mm)
};
```

struct mm_struct
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/mm_types.h/mm_struct.md

swapper_pg_dir
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/kernel/head.S/swapper_pg_dir.md

### aries

```
c0004000 A swapper_pg_dir
```