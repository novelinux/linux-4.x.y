dup_task_struct
========================================

path: kernel/fork.c
```
int __attribute__((weak)) arch_dup_task_struct(struct task_struct *dst,
                           struct task_struct *src)
{
    *dst = *src;
    return 0;
}

static struct task_struct *dup_task_struct(struct task_struct *orig)
{
    struct task_struct *tsk;
    struct thread_info *ti;
    unsigned long *stackend;
    int node = tsk_fork_get_node(orig);
    int err;

    prepare_to_copy(orig);

    tsk = alloc_task_struct_node(node);
    if (!tsk)
        return NULL;

    ti = alloc_thread_info_node(tsk, node);
    if (!ti) {
        free_task_struct(tsk);
        return NULL;
    }

    err = arch_dup_task_struct(tsk, orig);
    if (err)
        goto out;

    tsk->stack = ti;

    setup_thread_stack(tsk, orig);
    clear_user_return_notifier(tsk);
    clear_tsk_need_resched(tsk);
    // 设置栈结束标志防止栈溢出
    stackend = end_of_stack(tsk);
    // #define STACK_END_MAGIC 0x57AC6E9D (include/linux/magic.h)
    *stackend = STACK_END_MAGIC;    /* for overflow detection */

#ifdef CONFIG_CC_STACKPROTECTOR
    tsk->stack_canary = get_random_int();
#endif

    /*
     * One for us, one for whoever does the "release_task()" (usually
     * parent)
     */
    atomic_set(&tsk->usage, 2);
#ifdef CONFIG_BLK_DEV_IO_TRACE
    tsk->btrace_seq = 0;
#endif
    tsk->splice_pipe = NULL;

    account_kernel_stack(ti, 1);

    return tsk;

out:
    free_thread_info(ti);
    free_task_struct(tsk);
    return NULL;
}
```

alloc_thread_info_node
----------------------------------------

path: kernel/fork.c
```
static struct thread_info *alloc_thread_info_node(struct task_struct *tsk,
       int node)
{
#ifdef CONFIG_DEBUG_STACK_USAGE
    gfp_t mask = GFP_KERNEL | __GFP_ZERO;
#else
    gfp_t mask = GFP_KERNEL;
#endif
    struct page *page = alloc_pages_node(node, mask, THREAD_SIZE_ORDER);

    return page ? page_address(page) : NULL;
}
```

这里THREAD_SIZE_ORDER值为1，也就是说这个thread_info结构需要2个页8KB的空间。
这个8KB空间分为两部分，一部分保存thread_info值，另一部分当做线程的内核栈来用。
也就是8KB空间的起始位置+sizeof(thread_info)的位置。

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/fork.c/res/kernel_stack.jpg

end_of_stack
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/sched.h/end_of_stack.md
