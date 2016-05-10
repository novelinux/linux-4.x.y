binfmt_elf
========================================

path: fs/binfmt_elf.c
```
static struct linux_binfmt elf_format = {
    .module       = THIS_MODULE,
    .load_binary  = load_elf_binary,
    .load_shlib   = load_elf_library,
    .core_dump    = elf_core_dump,
    .min_coredump = ELF_EXEC_PAGESIZE,
};
```

load_elf_binary
----------------------------------------

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/fs/binfmt_elf_c/load_elf_binary.md
