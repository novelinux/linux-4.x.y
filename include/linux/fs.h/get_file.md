get_file
========================================

path: include/linux/fs.h
```
static inline struct file *get_file(struct file *f)
{
    atomic_long_inc(&f->f_count);
    return f;
}
```