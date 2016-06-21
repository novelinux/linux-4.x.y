fdget_pos
========================================

path: fs/read_write.c
```
static inline struct fd fdget_pos(int fd)
{
    return __to_fd(__fdget_pos(fd));
}
```

__fdget_pos
----------------------------------------

__to_fd
----------------------------------------