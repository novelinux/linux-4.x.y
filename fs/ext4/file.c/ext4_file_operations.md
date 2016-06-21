ext4_file_operations
========================================

path: fs/ext4/file.c
```
const struct file_operations ext4_file_operations = {
    .llseek        = ext4_llseek,
    .read_iter    = generic_file_read_iter,
```

write_iter
----------------------------------------

```
    .write_iter    = ext4_file_write_iter,
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/ext4/file.c/ext4_file_write_iter.md

unlocked_ioctl
----------------------------------------

```
    .unlocked_ioctl = ext4_ioctl,
#ifdef CONFIG_COMPAT
    .compat_ioctl    = ext4_compat_ioctl,
#endif
    .mmap        = ext4_file_mmap,
```

open
----------------------------------------

```
    .open        = ext4_file_open,
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/ext4/file.c/ext4_file_open.md

release
----------------------------------------

```
    .release    = ext4_release_file,
    .fsync        = ext4_sync_file,
    .splice_read    = generic_file_splice_read,
    .splice_write    = iter_file_splice_write,
    .fallocate    = ext4_fallocate,
};
```
