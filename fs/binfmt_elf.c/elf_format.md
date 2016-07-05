binfmt_elf
========================================

path: fs/binfmt_elf.c
```
static struct linux_binfmt elf_format = {
    .module       = THIS_MODULE,
```

load_elf_binary
----------------------------------------

```
    .load_binary  = load_elf_binary,
```

https://github.com/novelinux/linux-4.x.y/tree/master/fs/binfmt_elf.c/load_elf_binary.md

load_elf_library
----------------------------------------

```
    .load_shlib   = load_elf_library,
    .core_dump    = elf_core_dump,
    .min_coredump = ELF_EXEC_PAGESIZE,
};
```
