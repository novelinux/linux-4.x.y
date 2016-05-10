setup_machine_tags
========================================

path: arch/arm/kernel/atags_parse.c
```
const struct machine_desc * __init
setup_machine_tags(phys_addr_t __atags_pointer, unsigned int machine_nr)
{
    struct tag *tags = (struct tag *)&default_tags;
    const struct machine_desc *mdesc = NULL, *p;
    char *from = default_command_line;

    default_tags.mem.start = PHYS_OFFSET;

    /*
     * locate machine in the list of supported machines.
     */
    for_each_machine_desc(p)
        if (machine_nr == p->nr) {
            pr_info("Machine: %s\n", p->name);
            mdesc = p;
            break;
        }

    if (!mdesc) {
        early_print("\nError: unrecognized/unsupported machine ID"
                " (r1 = 0x%08x).\n\n", machine_nr);
        dump_machine_table(); /* does not return */
    }

    if (__atags_pointer)
        tags = phys_to_virt(__atags_pointer);
    else if (mdesc->atag_offset)
        tags = (void *)(PAGE_OFFSET + mdesc->atag_offset);

#if defined(CONFIG_DEPRECATED_PARAM_STRUCT)
    /*
     * If we have the old style parameters, convert them to
     * a tag list.
     */
    if (tags->hdr.tag != ATAG_CORE)
        convert_to_tag_list(tags);
#endif
    if (tags->hdr.tag != ATAG_CORE) {
        early_print("Warning: Neither atags nor dtb found\n");
        tags = (struct tag *)&default_tags;
    }

    if (mdesc->fixup)
        mdesc->fixup(tags, &from);

    if (tags->hdr.tag == ATAG_CORE) {
        if (memblock_phys_mem_size())
            squash_mem_tags(tags);
        save_atags(tags);
        parse_tags(tags);
    }

    /* parse_early_param needs a boot_command_line */
    strlcpy(boot_command_line, from, COMMAND_LINE_SIZE);

    return mdesc;
}
```
