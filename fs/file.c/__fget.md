__fget
========================================

path: fs/file.c
```
static struct file *__fget(unsigned int fd, fmode_t mask)
{
    struct files_struct *files = current->files;
    struct file *file;

    rcu_read_lock();
loop:
    file = fcheck_files(files, fd);
    if (file) {
        /* File object ref couldn't be taken.
         * dup2() atomicity guarantee is the reason
         * we loop to catch the new file (or NULL pointer)
         */
        if (file->f_mode & mask)
            file = NULL;
        else if (!get_file_rcu(file))
            goto loop;
    }
    rcu_read_unlock();

    return file;
}
```