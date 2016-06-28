__init_task_data
========================================

path: include/linux/init_task.h
```
/* Attach to the init_task data structure for proper alignment */
#define __init_task_data __attribute__((__section__(".data..init_task")))
```

.data..init_task
----------------------------------------

该section在vmlinux.lds.S中定义如下所示:

path: arch/arm/kernel/vmlinux.lds.S
```
    .data : AT(__data_loc) {
        _data = .;        /* address in memory */
        _sdata = .;

        /*
         * first, the init task union, aligned
         * to an 8192 byte boundary.
         */
        INIT_TASK_DATA(THREAD_SIZE)
     }
```

path: include/asm-generic/vmlinux.lds.h
```
#define INIT_TASK_DATA(align)                                           \
        . = ALIGN(align);                                               \
        *(.data..init_task)
```