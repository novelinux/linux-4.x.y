set_brk
========================================

path: fs/binfmt_elf.c
```
static int set_brk(unsigned long start, unsigned long end)
{
    start = ELF_PAGEALIGN(start);
    end = ELF_PAGEALIGN(end);
    if (end > start) {
        unsigned long addr;
        addr = vm_brk(start, end - start);
        if (BAD_ADDR(addr))
            return addr;
    }
    current->mm->start_brk = current->mm->brk = end;
    return 0;
}
```