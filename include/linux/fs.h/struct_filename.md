struct filename
========================================

path: include/linux/fs.h
```
struct audit_names;
struct filename {
    const char         *name;    /* pointer to actual string */
    const __user char  *uptr;    /* original userland pointer */
    struct audit_names *aname;
    int                refcnt;
    const char         iname[];
};
```