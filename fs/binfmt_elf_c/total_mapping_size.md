total_mapping_size
========================================

path: fs/binfmt_elf.c
```
static unsigned long total_mapping_size(struct elf_phdr *cmds, int nr)
{
    int i, first_idx = -1, last_idx = -1;

    for (i = 0; i < nr; i++) {
        if (cmds[i].p_type == PT_LOAD) {
            last_idx = i;
            if (first_idx == -1)
                first_idx = i;
        }
    }
    if (first_idx == -1)
        return 0;

    return cmds[last_idx].p_vaddr + cmds[last_idx].p_memsz -
                ELF_PAGESTART(cmds[first_idx].p_vaddr);
}
```