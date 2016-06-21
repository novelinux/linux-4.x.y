init_sync_kiocb
========================================

path: include/linux/fs.h
```
static inline void init_sync_kiocb(struct kiocb *kiocb, struct file *filp)
{
    *kiocb = (struct kiocb) {
        .ki_filp = filp,
        .ki_flags = iocb_flags(filp),
    };
}
```