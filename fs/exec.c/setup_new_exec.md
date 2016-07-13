setup_new_exec
========================================

Arguments
----------------------------------------

path: fs/exec.c
```
void setup_new_exec(struct linux_binprm * bprm)
{
```

arch_pick_mmap_layout
----------------------------------------

```
    arch_pick_mmap_layout(current->mm);
```

current->mm经过函数flush_old_exec以后已经被替换成了新程序在bprm_mm_init
函数中创建的进程虚拟地址空间. arch_pick_mmap_layout函数的作用是选择新进程
的虚拟地址空间布局,如果对应的体系结构没有提供一个具体的函数，则使用内核默认
的历程.

### ARM

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/mm/mmap.c/arch_pick_mmap_layout.md

Set task
----------------------------------------

### sas_ss_sp

```
    /* This is the point of no return */
    current->sas_ss_sp = current->sas_ss_size = 0;
```

### set_dumpable

```
    if (uid_eq(current_euid(), current_uid()) && gid_eq(current_egid(), current_gid()))
        set_dumpable(current->mm, SUID_DUMP_USER);
    else
        set_dumpable(current->mm, suid_dumpable);
```

### __set_task_comm

__set_task_comm函数用来设置当前进程的comm域为二进制文件的名称.

```
    perf_event_exec();
    __set_task_comm(current, kbasename(bprm->filename), true);
```

### mm->task_size

设置当前进程的进程虚拟地址空间大小为TASK_SIZE

```
    /* Set the new mm task size. We have to do that late because it may
     * depend on TIF_32BIT which is only updated in flush_thread() on
     * some architectures like powerpc
     */
    current->mm->task_size = TASK_SIZE;

    /* install the new credentials */
    if (!uid_eq(bprm->cred->uid, current_euid()) ||
        !gid_eq(bprm->cred->gid, current_egid())) {
        current->pdeath_signal = 0;
    } else {
        would_dump(bprm, bprm->file);
        if (bprm->interp_flags & BINPRM_FLAGS_ENFORCE_NONDUMP)
            set_dumpable(current->mm, suid_dumpable);
    }

    /* An exec changes our domain. We are no longer part of the thread
       group */
    current->self_exec_id++;
    flush_signal_handlers(current, 0);
```

#### TASK_SIZE

##### ARM

https://github.com/novelinux/linux-4.x.y/blob/master/arch/arm/include/asm/memory.h/TASK_SIZE.md

do_close_on_exec
----------------------------------------

最后检查当前进程的credential和对当前进程files进行do_close_on_exec操作

```
    do_close_on_exec(current->files);
}
EXPORT_SYMBOL(setup_new_exec);
```
