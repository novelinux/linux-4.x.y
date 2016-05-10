exec_binprm
========================================

path: fs/exec.c
```
static int exec_binprm(struct linux_binprm *bprm)
{
    pid_t old_pid, old_vpid;
    int ret;

    /* Need to fetch pid before load_binary changes it */
    old_pid = current->pid;
    rcu_read_lock();
    old_vpid = task_pid_nr_ns(current, task_active_pid_ns(current->parent));
    rcu_read_unlock();

    ret = search_binary_handler(bprm);
    if (ret >= 0) {
        audit_bprm(bprm);
        trace_sched_process_exec(current, old_pid, bprm);
        ptrace_event(PTRACE_EVENT_EXEC, old_vpid);
        proc_exec_connector(current);
    }

    return ret;
}
```

在exec_binprm函数中调用search_binary_handler函数查找一种适当的二进制格式，
用于所要执行的特定文件. 二进制格式处理程序负责将新程序的数据加载到旧的地址
空间.

search_binary_handler
----------------------------------------

path: fs/exec.c
```
/*
 * cycle the list of binary formats handler, until one recognizes the image
 */
int search_binary_handler(struct linux_binprm *bprm)
{
    bool need_retry = IS_ENABLED(CONFIG_MODULES);
    struct linux_binfmt *fmt;
    int retval;

    /* This allows 4 levels of binfmt rewrites before failing hard. */
    if (bprm->recursion_depth > 5)
        return -ELOOP;

    retval = security_bprm_check(bprm);
    if (retval)
        return retval;

    retval = -ENOENT;
 retry:
    read_lock(&binfmt_lock);
    list_for_each_entry(fmt, &formats, lh) {
        if (!try_module_get(fmt->module))
            continue;
        read_unlock(&binfmt_lock);
        bprm->recursion_depth++;
        retval = fmt->load_binary(bprm);
        read_lock(&binfmt_lock);
        put_binfmt(fmt);
        bprm->recursion_depth--;
        if (retval < 0 && !bprm->mm) {
            /* we got to flush_old_exec() and failed after it */
            read_unlock(&binfmt_lock);
            force_sigsegv(SIGSEGV, current);
            return retval;
        }
        if (retval != -ENOEXEC || !bprm->file) {
            read_unlock(&binfmt_lock);
            return retval;
        }
    }
    read_unlock(&binfmt_lock);

    if (need_retry) {
        if (printable(bprm->buf[0]) && printable(bprm->buf[1]) &&
            printable(bprm->buf[2]) && printable(bprm->buf[3]))
            return retval;
        if (request_module("binfmt-%04x", *(ushort *)(bprm->buf + 2)) < 0)
            return retval;
        need_retry = false;
        goto retry;
    }

    return retval;
}
EXPORT_SYMBOL(search_binary_handler);
```

扫描formats链表，并尽力应用每个元素的load_binary方法，
把bprm传递给这个函数。只要load_binary方法成功应答了文件的
可执行格式，对formats扫描终止。

在Linux内核中，每种二进制格式都表示为下列数据结构:

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/binfmts.h/binfmts.md

每种二进制格式首先必须使用register_binfmt向内核注册.该函数的目的是
向一个链表增加一个新的二进制格式，该链表的表头是:

path: fs/exec.c
```
static LIST_HEAD(formats);
```

常用ELF二进制文件是使用load_elf_binary来装载的, 具体实现如下所示:

https://github.com/novelinux/linux-4.x.y/tree/master/fs/binfmt_elf_c/binfmt_elf.md
