set_binfmt
========================================

path: fs/exec.c
```
void set_binfmt(struct linux_binfmt *new)
{
    struct mm_struct *mm = current->mm;

    if (mm->binfmt)
        module_put(mm->binfmt->module);

    mm->binfmt = new;
    if (new)
        __module_get(new->module);
}
EXPORT_SYMBOL(set_binfmt);
```