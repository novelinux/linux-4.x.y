# getname

path: fs/namei.c
```
struct filename *
getname(const char __user * filename)
{
    return getname_flags(filename, 0, NULL);
}
```

## struct filename

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/fs.h/struct_filename.md

## getname_flags

https://github.com/novelinux/linux-4.x.y/tree/master/fs/namei.c/getname_flags.md
