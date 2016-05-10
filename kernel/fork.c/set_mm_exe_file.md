set_mm_exe_file
========================================

path: kernel/fork.c
```
void set_mm_exe_file(struct mm_struct *mm, struct file *new_exe_file)
{
    if (new_exe_file)
        get_file(new_exe_file);
    if (mm->exe_file)
        fput(mm->exe_file);
    mm->exe_file = new_exe_file;
}
```