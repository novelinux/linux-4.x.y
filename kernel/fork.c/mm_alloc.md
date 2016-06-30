mm_alloc
========================================

Arguments
----------------------------------------

path: kernel/fork.c
```
/*
 * Allocate and initialize an mm_struct.
 */
struct mm_struct *mm_alloc(void)
{
    struct mm_struct *mm;
```

allocate_mm
----------------------------------------

```
    mm = allocate_mm();
    if (!mm)
        return NULL;

    memset(mm, 0, sizeof(*mm));
```

https://github.com/novelinux/linux-4.x.y/blob/master/kernel/fork.c/allocate_mm.md

mm_init
----------------------------------------

```
    return mm_init(mm, current);
}
```

https://github.com/novelinux/linux-4.x.y/blob/master/kernel/fork.c/mm_init.md
