setup_arg_pages
========================================

Source
----------------------------------------

path: fs/exec.c
```
/*
 * Finalizes the stack vm_area_struct. The flags and permissions are updated,
 * the stack is optionally relocated, and some extra space is added.
 */
int setup_arg_pages(struct linux_binprm *bprm,
            unsigned long stack_top,
            int executable_stack)
{
    unsigned long ret;
    unsigned long stack_shift;
    struct mm_struct *mm = current->mm;
    struct vm_area_struct *vma = bprm->vma;
    struct vm_area_struct *prev = NULL;
    unsigned long vm_flags;
    unsigned long stack_base;
    unsigned long stack_size;
    unsigned long stack_expand;
    unsigned long rlim_stack;

#ifdef CONFIG_STACK_GROWSUP
    /* Limit stack size */
    stack_base = rlimit_max(RLIMIT_STACK);
    if (stack_base > STACK_SIZE_MAX)
        stack_base = STACK_SIZE_MAX;

    /* Make sure we didn't let the argument array grow too large. */
    if (vma->vm_end - vma->vm_start > stack_base)
        return -ENOMEM;

    stack_base = PAGE_ALIGN(stack_top - stack_base);

    stack_shift = vma->vm_start - stack_base;
    mm->arg_start = bprm->p - stack_shift;
    bprm->p = vma->vm_end - stack_shift;
#else
    stack_top = arch_align_stack(stack_top);
    stack_top = PAGE_ALIGN(stack_top);

    if (unlikely(stack_top < mmap_min_addr) ||
        unlikely(vma->vm_end - vma->vm_start >= stack_top - mmap_min_addr))
        return -ENOMEM;

    stack_shift = vma->vm_end - stack_top;

    bprm->p -= stack_shift;
    mm->arg_start = bprm->p;
#endif

    if (bprm->loader)
        bprm->loader -= stack_shift;
    bprm->exec -= stack_shift;

    down_write(&mm->mmap_sem);
    vm_flags = VM_STACK_FLAGS;

    /*
     * Adjust stack execute permissions; explicitly enable for
     * EXSTACK_ENABLE_X, disable for EXSTACK_DISABLE_X and leave alone
     * (arch default) otherwise.
     */
    if (unlikely(executable_stack == EXSTACK_ENABLE_X))
        vm_flags |= VM_EXEC;
    else if (executable_stack == EXSTACK_DISABLE_X)
        vm_flags &= ~VM_EXEC;
    vm_flags |= mm->def_flags;
    vm_flags |= VM_STACK_INCOMPLETE_SETUP;

    ret = mprotect_fixup(vma, &prev, vma->vm_start, vma->vm_end,
            vm_flags);
    if (ret)
        goto out_unlock;
    BUG_ON(prev != vma);

    /* Move stack pages down in memory. */
    if (stack_shift) {
        ret = shift_arg_pages(vma, stack_shift);
        if (ret)
            goto out_unlock;
    }

    /* mprotect_fixup is overkill to remove the temporary stack flags */
    vma->vm_flags &= ~VM_STACK_INCOMPLETE_SETUP;
    stack_expand = 131072UL; /* randomly 32*4k (or 2*64k) pages */
    stack_size = vma->vm_end - vma->vm_start;
    /*
     * Align this down to a page boundary as expand_stack
     * will align it up.
     */
    rlim_stack = rlimit(RLIMIT_STACK) & PAGE_MASK;
#ifdef CONFIG_STACK_GROWSUP
    if (stack_size + stack_expand > rlim_stack)
        stack_base = vma->vm_start + rlim_stack;
    else
        stack_base = vma->vm_end + stack_expand;
#else
    if (stack_size + stack_expand > rlim_stack)
        stack_base = vma->vm_end - rlim_stack;
    else
        stack_base = vma->vm_start - stack_expand;
#endif
    current->mm->start_stack = bprm->p;
    ret = expand_stack(vma, stack_base);
    if (ret)
        ret = -EFAULT;

out_unlock:
    up_write(&mm->mmap_sem);
    return ret;
}
EXPORT_SYMBOL(setup_arg_pages);
```

1.CONFIG_STACK_GROWSUP
----------------------------------------

改内核配置项用来决定进程栈的增长方向是自下而上增长的，通常，栈的增长方向都是自上而下
增长的，于是编译时执行的是else中的代码段. 如下所示:

2.计算stack_shift位移值
----------------------------------------

```
    /* stack_top进行对齐调整 */
    stack_top = arch_align_stack(stack_top);
    stack_top = PAGE_ALIGN(stack_top);

    if (unlikely(stack_top < mmap_min_addr) ||
        unlikely(vma->vm_end - vma->vm_start >= stack_top - mmap_min_addr))
        return -ENOMEM;
    /* vma->vm_end在__bprm_mm_init中被设置为STACK_TOP_MAX.
     * 通常STACK_TOP_MAX的值等于STACK_TOP的值为TASK_SIZE.
     */
    stack_shift = vma->vm_end - stack_top;
```

stack_top的初始值是randomize_stack_top(STACK_TOP)的返回值.
该值的大小为STACK_TOP的值加上或减去(栈自底向上或者自顶向下增长)
一个随机值.

path: fs/binfmt_elf.c
```
static unsigned long randomize_stack_top(unsigned long stack_top)
{
     unsigned int random_variable = 0;

     if ((current->flags & PF_RANDOMIZE) &&
         !(current->personality & ADDR_NO_RANDOMIZE)) {
         random_variable = get_random_int() & STACK_RND_MASK;
         random_variable <<= PAGE_SHIFT;
     }
#ifdef CONFIG_STACK_GROWSUP
     return PAGE_ALIGN(stack_top) + random_variable;
#else
     return PAGE_ALIGN(stack_top) - random_variable;
#endif
}
```

3.设置bprm->p和mm->arg_start
----------------------------------------

bprm->p在__bprm_mm_init函数中被设置为vma->vm_end - sizeof (void*).
也就是STACK_TOP_MAX - sizeof (void *).
接下来根据之前计算的位移值stack_shift调整bprm->p
接下来将进程地址空间参数列表的起始地址arg_start设置为bprm->p指向的地址.
由于在do_execveat_common函数中将bprm->exec设置为等于bprm->p，
所以同时调整bprm->exec所指向的地址. 在这里bprm->loader的值为0，
所以不再作调整.

```
    bprm->p -= stack_shift;
    mm->arg_start = bprm->p;
    ...
    if (bprm->loader)
        bprm->loader -= stack_shift;
    bprm->exec -= stack_shift;
```

4.设置vma所描述栈区域的标志
----------------------------------------

```
    ...
    vm_flags = VM_STACK_FLAGS;

    /*
     * Adjust stack execute permissions; explicitly enable for
     * EXSTACK_ENABLE_X, disable for EXSTACK_DISABLE_X and leave alone
     * (arch default) otherwise.
     */
    // 设置该栈区域是否可执行的标志.
    if (unlikely(executable_stack == EXSTACK_ENABLE_X))
        vm_flags |= VM_EXEC;
    else if (executable_stack == EXSTACK_DISABLE_X)
        vm_flags &= ~VM_EXEC;
    vm_flags |= mm->def_flags;
    vm_flags |= VM_STACK_INCOMPLETE_SETUP;
    ...
    /* mprotect_fixup is overkill to remove the temporary stack flags */
    vma->vm_flags &= ~VM_STACK_INCOMPLETE_SETUP;
    ...
```

5.mprotect_fixup
----------------------------------------

mprotect_fixup函数用来检查该区域的安全性.

6.shift_arg_pages
----------------------------------------

在之前的bprm_mm_init函数中我们创建了一个指向STACK_TOP_MAX的临时栈,
在当前函数setup_arg_pages我们重新确认了堆栈的位置之后我们需要重新
使用stack_shift位移堆栈.具体实现如下所示:

https://github.com/novelinux/linux-4.x.y/tree/master/fs/exec_c/shift_arg_pages.md

7.扩展堆栈
-----------------------------------------

函数最后一步操作就是扩展堆栈，并且将堆栈的起始位置设置为bprm->p指向的
位置处.

```
    stack_expand = 131072UL; /* randomly 32*4k (or 2*64k) pages */
    stack_size = vma->vm_end - vma->vm_start;
    /*
     * Align this down to a page boundary as expand_stack
     * will align it up.
     */
    rlim_stack = rlimit(RLIMIT_STACK) & PAGE_MASK;
#ifdef CONFIG_STACK_GROWSUP
    ...
#else
    if (stack_size + stack_expand > rlim_stack)
        stack_base = vma->vm_end - rlim_stack;
    else
        stack_base = vma->vm_start - stack_expand;
#endif
    current->mm->start_stack = bprm->p;
    ret = expand_stack(vma, stack_base);
```