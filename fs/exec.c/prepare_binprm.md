prepare_binprm
========================================

Arguments
----------------------------------------

path: fs/exec.c
```
/*
 * Fill the binprm structure from the inode.
 * Check permissions, then read the first 128 (BINPRM_BUF_SIZE) bytes
 *
 * This may be called multiple times for binary chains (scripts for example).
 */
int prepare_binprm(struct linux_binprm *bprm)
{
    int retval;
```

bprm_fill_uid
----------------------------------------

```
    bprm_fill_uid(bprm);
```

https://github.com/novelinux/linux-4.x.y/tree/master/fs/exec.c/bprm_fill_uid.md

security_bprm_set_creds
----------------------------------------

```
    /* fill in binprm security blob */
    retval = security_bprm_set_creds(bprm);
    if (retval)
        return retval;
    bprm->cred_prepared = 1;
```

kernel_read
----------------------------------------

读取可执行文件的前128个字节填充bprm的buf字段.

```
    memset(bprm->buf, 0, BINPRM_BUF_SIZE);
    return kernel_read(bprm->file, 0, bprm->buf, BINPRM_BUF_SIZE);
}

EXPORT_SYMBOL(prepare_binprm);
```
