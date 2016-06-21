__fdget
========================================

path: fs/file.c
```
unsigned long __fdget(unsigned int fd)
{
    return __fget_light(fd, FMODE_PATH);
}
EXPORT_SYMBOL(__fdget);
```

__fget_light
----------------------------------------

https://github.com/novelinux/linux-4.x.y/blob/master/fs/file.c/__fget_light.md
