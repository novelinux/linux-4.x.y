struct fd
========================================

file
----------------------------------------

path: include/linux/file.h
```
struct fd {
    struct file *file;
```

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/fs.h/struct_file.md

flags
----------------------------------------

```
    unsigned int flags;
};
#define FDPUT_FPUT       1
#define FDPUT_POS_UNLOCK 2
```