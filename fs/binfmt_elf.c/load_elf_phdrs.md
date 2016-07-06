load_elf_phdrs
========================================

Arguments
----------------------------------------

path: fs/binfmt_elf.c
```
/**
 * load_elf_phdrs() - load ELF program headers
 * @elf_ex:   ELF header of the binary whose program headers should be loaded
 * @elf_file: the opened ELF binary file
 *
 * Loads ELF program headers from the binary file elf_file, which has the ELF
 * header pointed to by elf_ex, into a newly allocated array. The caller is
 * responsible for freeing the allocated data. Returns an ERR_PTR upon failure.
 */
static struct elf_phdr *load_elf_phdrs(struct elfhdr *elf_ex,
                       struct file *elf_file)
{
    struct elf_phdr *elf_phdata = NULL;
    int retval, size, err = -1;
```

Check
----------------------------------------

```
    /*
     * If the size of this structure has changed, then punt, since
     * we will be doing the wrong thing.
     */
    /* 检查elf header 中e_phentsize 大小是否同struct elf_phdr大小相同. */
    if (elf_ex->e_phentsize != sizeof(struct elf_phdr))
        goto out;

    /* Sanity check the number of program headers... */
    /* 检查Program Header中的项的数目是否合法. */
    if (elf_ex->e_phnum < 1 ||
        elf_ex->e_phnum > 65536U / sizeof(struct elf_phdr))
        goto out;

    /* ...and their total size. */
    /* 计算二进制文件中所有Program Header大小. */
    size = sizeof(struct elf_phdr) * elf_ex->e_phnum;
    if (size > ELF_MIN_ALIGN)
        goto out;
```

Read
----------------------------------------

```
    elf_phdata = kmalloc(size, GFP_KERNEL);
    if (!elf_phdata)
        goto out;

    /* Read in the program headers */
    retval = kernel_read(elf_file, elf_ex->e_phoff,
                 (char *)elf_phdata, size);
    if (retval != size) {
        err = (retval < 0) ? retval : -EIO;
        goto out;
    }

    /* Success! */
    err = 0;
out:
    if (err) {
        kfree(elf_phdata);
        elf_phdata = NULL;
    }
    return elf_phdata;
}
```
