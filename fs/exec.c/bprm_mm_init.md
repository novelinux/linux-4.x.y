bprm_mm_init
========================================

Arguments
----------------------------------------

path: fs/exec.c
```
/*
 * Create a new mm_struct and populate it with a temporary stack
 * vm_area_struct.  We don't have enough context at this point to set the stack
 * flags, permissions, and offset, so we use temporary values.  We'll update
 * them later in setup_arg_pages().
 */
static int bprm_mm_init(struct linux_binprm *bprm)
{
    int err;
    struct mm_struct *mm = NULL;
```

mm_alloc
----------------------------------------

```
    bprm->mm = mm = mm_alloc();
    err = -ENOMEM;
    if (!mm)
        goto err;
```

创建一个mm_struct实例管理新进程的进程地址空间.

https://github.com/novelinux/linux-4.x.y/blob/master/kernel/fork.c/mm_alloc.md

__bprm_mm_init
----------------------------------------

```
    err = __bprm_mm_init(bprm);
    if (err)
        goto err;

    return 0;
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/exec.c/__bprm_mm_init.md

err
----------------------------------------

```
err:
    if (mm) {
        bprm->mm = NULL;
        mmdrop(mm);
    }

    return err;
}
```
