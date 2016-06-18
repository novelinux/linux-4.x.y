do_dentry_open
========================================

Arguments
----------------------------------------

path: fs/open.c
```
static int do_dentry_open(struct file *f,
              struct inode *inode,
              int (*open)(struct inode *, struct file *),
              const struct cred *cred)
{
    static const struct file_operations empty_fops = {};
    int error;
```

Configure
----------------------------------------

```
    f->f_mode = OPEN_FMODE(f->f_flags) | FMODE_LSEEK |
                FMODE_PREAD | FMODE_PWRITE;

    path_get(&f->f_path);
    f->f_inode = inode;
    f->f_mapping = inode->i_mapping;

    if (unlikely(f->f_flags & O_PATH)) {
        f->f_mode = FMODE_PATH;
        f->f_op = &empty_fops;
        return 0;
    }

    if (f->f_mode & FMODE_WRITE && !special_file(inode->i_mode)) {
        error = get_write_access(inode);
        if (unlikely(error))
            goto cleanup_file;
        error = __mnt_want_write(f->f_path.mnt);
        if (unlikely(error)) {
            put_write_access(inode);
            goto cleanup_file;
        }
        f->f_mode |= FMODE_WRITER;
    }

    /* POSIX.1-2008/SUSv4 Section XSI 2.9.7 */
    if (S_ISREG(inode->i_mode))
        f->f_mode |= FMODE_ATOMIC_POS;

    f->f_op = fops_get(inode->i_fop);
    if (unlikely(WARN_ON(!f->f_op))) {
        error = -ENODEV;
        goto cleanup_all;
    }

    error = security_file_open(f, cred);
    if (error)
        goto cleanup_all;

    error = break_lease(inode, f->f_flags);
    if (error)
        goto cleanup_all;
```

open
----------------------------------------

```
    if (!open)
        open = f->f_op->open;
    if (open) {
        error = open(inode, f);
        if (error)
            goto cleanup_all;
    }
    if ((f->f_mode & (FMODE_READ | FMODE_WRITE)) == FMODE_READ)
        i_readcount_inc(inode);
    if ((f->f_mode & FMODE_READ) &&
         likely(f->f_op->read || f->f_op->read_iter))
        f->f_mode |= FMODE_CAN_READ;
    if ((f->f_mode & FMODE_WRITE) &&
         likely(f->f_op->write || f->f_op->write_iter))
        f->f_mode |= FMODE_CAN_WRITE;

    f->f_flags &= ~(O_CREAT | O_EXCL | O_NOCTTY | O_TRUNC);

    file_ra_state_init(&f->f_ra, f->f_mapping->host->i_mapping);

    return 0;
```

### ext4

https://github.com/novelinux/linux-4.x.y/blob/master/fs/ext4/file.c/ext4_file_operations.md

cleanup_all
----------------------------------------

```
cleanup_all:
    fops_put(f->f_op);
    if (f->f_mode & FMODE_WRITER) {
        put_write_access(inode);
        __mnt_drop_write(f->f_path.mnt);
    }
cleanup_file:
    path_put(&f->f_path);
    f->f_path.mnt = NULL;
    f->f_path.dentry = NULL;
    f->f_inode = NULL;
    return error;
}
```