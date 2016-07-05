search_binary_handler
========================================

Arguments
----------------------------------------

path: fs/exec.c
```
#define printable(c) (((c)=='\t') || ((c)=='\n') || (0x20<=(c) && (c)<=0x7e))
/*
 * cycle the list of binary formats handler, until one recognizes the image
 */
int search_binary_handler(struct linux_binprm *bprm)
{
    bool need_retry = IS_ENABLED(CONFIG_MODULES);
    struct linux_binfmt *fmt;
    int retval;

    /* This allows 4 levels of binfmt rewrites before failing hard. */
    if (bprm->recursion_depth > 5)
        return -ELOOP;
```

security_bprm_check
----------------------------------------

```
    retval = security_bprm_check(bprm);
    if (retval)
        return retval;

    retval = -ENOENT;
```

retry
----------------------------------------

扫描formats链表，并尽力应用每个元素的load_binary方法，把bprm传递给这个函数。
只要load_binary方法成功应答了文件的可执行格式，对formats扫描终止。

```
 retry:
    read_lock(&binfmt_lock);
    list_for_each_entry(fmt, &formats, lh) {
        if (!try_module_get(fmt->module))
            continue;
        read_unlock(&binfmt_lock);
        bprm->recursion_depth++;
        retval = fmt->load_binary(bprm);
        read_lock(&binfmt_lock);
        put_binfmt(fmt);
        bprm->recursion_depth--;
        if (retval < 0 && !bprm->mm) {
            /* we got to flush_old_exec() and failed after it */
            read_unlock(&binfmt_lock);
            force_sigsegv(SIGSEGV, current);
            return retval;
        }
        if (retval != -ENOEXEC || !bprm->file) {
            read_unlock(&binfmt_lock);
            return retval;
        }
    }
    read_unlock(&binfmt_lock);

    if (need_retry) {
        if (printable(bprm->buf[0]) && printable(bprm->buf[1]) &&
            printable(bprm->buf[2]) && printable(bprm->buf[3]))
            return retval;
        if (request_module("binfmt-%04x", *(ushort *)(bprm->buf + 2)) < 0)
            return retval;
        need_retry = false;
        goto retry;
    }

    return retval;
}
EXPORT_SYMBOL(search_binary_handler);
```

### ELF

常用ELF二进制文件是使用load_elf_binary来装载的, 具体实现如下所示:

https://github.com/novelinux/linux-4.x.y/tree/master/fs/binfmt_elf.c/README.md
