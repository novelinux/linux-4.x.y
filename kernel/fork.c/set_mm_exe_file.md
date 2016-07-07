set_mm_exe_file
========================================

Arguments
----------------------------------------

path: kernel/fork.c
```
/**
 * set_mm_exe_file - change a reference to the mm's executable file
 *
 * This changes mm's executable file (shown as symlink /proc/[pid]/exe).
 *
 * Main users are mmput() and sys_execve(). Callers prevent concurrent
 * invocations: in mmput() nobody alive left, in execve task is single
 * threaded. sys_prctl(PR_SET_MM_MAP/EXE_FILE) also needs to set the
 * mm->exe_file, but does so without using set_mm_exe_file() in order
 * to do avoid the need for any locks.
 */
void set_mm_exe_file(struct mm_struct *mm, struct file *new_exe_file)
{
    struct file *old_exe_file;

    /*
     * It is safe to dereference the exe_file without RCU as
     * this function is only called if nobody else can access
     * this mm -- see comment above for justification.
     */
    old_exe_file = rcu_dereference_raw(mm->exe_file);
```

get_file
----------------------------------------

```
    if (new_exe_file)
        get_file(new_exe_file);
```

https://github.com/novelinux/linux-4.x.y/blob/master/include/linux/fs.h/get_file.md

mm->exe_file
----------------------------------------

```
    rcu_assign_pointer(mm->exe_file, new_exe_file);
    if (old_exe_file)
        fput(old_exe_file);
}
```