__fget_light
========================================

Arguments
----------------------------------------

path: fs/file.c
```
/*
 * Lightweight file lookup - no refcnt increment if fd table isn't shared.
 *
 * You can use this instead of fget if you satisfy all of the following
 * conditions:
 * 1) You must call fput_light before exiting the syscall and returning control
 *    to userspace (i.e. you cannot remember the returned struct file * after
 *    returning to userspace).
 * 2) You must not call filp_close on the returned struct file * in between
 *    calls to fget_light and fput_light.
 * 3) You must not clone the current task in between the calls to fget_light
 *    and fput_light.
 *
 * The fput_needed flag returned by fget_light should be passed to the
 * corresponding fput_light.
 */
```

Arguments
----------------------------------------

```
static unsigned long __fget_light(unsigned int fd, fmode_t mask)
{
    struct files_struct *files = current->files;
    struct file *file;
```

__fcheck_files
----------------------------------------

```
    if (atomic_read(&files->count) == 1) {
        file = __fcheck_files(files, fd);
        if (!file || unlikely(file->f_mode & mask))
            return 0;
        return (unsigned long)file;
```

https://github.com/novelinux/linux-4.x.y/blob/master/include/linux/fdtable.h/__fcheck_files.md

__fget
----------------------------------------

```
    } else {
        file = __fget(fd, mask);
        if (!file)
            return 0;
        return FDPUT_FPUT | (unsigned long)file;
    }
}
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/file.c/__fget.md
