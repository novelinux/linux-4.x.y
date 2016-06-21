__fdget_pos
========================================

path: fs/file.c
```
unsigned long __fdget_pos(unsigned int fd)
{
    unsigned long v = __fdget(fd);
    struct file *file = (struct file *)(v & ~3);

    if (file && (file->f_mode & FMODE_ATOMIC_POS)) {
        if (file_count(file) > 1) {
            v |= FDPUT_POS_UNLOCK;
            mutex_lock(&file->f_pos_lock);
        }
    }
    return v;
}
```

__fdget
----------------------------------------

https://github.com/novelinux/linux-4.x.y/blob/master/fs/file.c/__fdget.md
