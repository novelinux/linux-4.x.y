acct_arg_size
========================================

Arguments
----------------------------------------

path: fs/exec.c
```
#ifdef CONFIG_MMU
/*
 * The nascent bprm->mm is not visible until exec_mmap() but it can
 * use a lot of memory, account these pages in current->mm temporary
 * for oom_badness()->get_mm_rss(). Once exec succeeds or fails, we
 * change the counter back via acct_arg_size(0).
 */
static void acct_arg_size(struct linux_binprm *bprm, unsigned long pages)
{
    struct mm_struct *mm = current->mm;
    long diff = (long)(pages - bprm->vma_pages);

    if (!mm || !diff)
        return;

    bprm->vma_pages = pages;
    add_mm_counter(mm, MM_ANONPAGES, diff);
}
```