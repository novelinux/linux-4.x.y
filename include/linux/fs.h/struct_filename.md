# struct filename

## name

path: include/linux/fs.h
```
struct audit_names;
struct filename {
    const char         *name;    /* pointer to actual string */
```

真实的名字

## uptr

```
    const __user char  *uptr;    /* original userland pointer */
```

原来的用户指针

## aname

```
    struct audit_names *aname;
    int                refcnt;
    const char         iname[];
};
```