setup_arg_pages
========================================

Arguments
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
```

mm->arg_start
----------------------------------------

CONFIG_STACK_GROWSUP 改内核配置项用来决定进程栈的增长方向是自下而上增长的，
通常，栈的增长方向都是自上而下增长的，于是编译时执行的是else中的代码段. 如下所示:

```
#ifdef CONFIG_STACK_GROWSUP
    /* Limit stack size */
    stack_base = rlimit_max(RLIMIT_STACK);
    if (stack_base > STACK_SIZE_MAX)
        stack_base = STACK_SIZE_MAX;

    /* Add space for stack randomization. */
    stack_base += (STACK_RND_MASK << PAGE_SHIFT);

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
```

bprm (loader, exec)
----------------------------------------

```
    if (bprm->loader)
        bprm->loader -= stack_shift;
    bprm->exec -= stack_shift;
```

vm_flags
----------------------------------------

```
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
```

mprotect_fixup
----------------------------------------

mprotect_fixup函数用来检查该区域的安全性.

```
    ret = mprotect_fixup(vma, &prev, vma->vm_start, vma->vm_end,
            vm_flags);
    if (ret)
        goto out_unlock;
    BUG_ON(prev != vma);
```

shift_arg_pages
----------------------------------------

```
    /* Move stack pages down in memory. */
    if (stack_shift) {
        ret = shift_arg_pages(vma, stack_shift);
        if (ret)
            goto out_unlock;
    }
```

https://github.com/novelinux/linux-4.x.y/tree/master/fs/exec.c/shift_arg_pages.md

current->mm->start_stack
----------------------------------------

```
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
```

expand_stack
----------------------------------------

函数最后一步操作就是扩展堆栈，并且将堆栈的起始位置设置为bprm->p指向的位置处.

```
    ret = expand_stack(vma, stack_base);
    if (ret)
        ret = -EFAULT;

out_unlock:
    up_write(&mm->mmap_sem);
    return ret;
}
EXPORT_SYMBOL(setup_arg_pages);
```

Layout
----------------------------------------

```
|--------------------------------------| 0xffffffff
|                                      |
|--------------------------------------| <- vma->end (STACK_TOP_MAX: 0xc0000000 - 16MB)
|                                      |
|--------------------------------------| <- [ bprm->p (vma->end - sizeof (void *)) ]
|            stack_shift               |
|--------------------------------------| <- current->mm->start_stack = mm->arg_start = bprm->p
|                                      |
|--------------------------------------| <- vma->start (vma->end - PAGE_SIZE)
```