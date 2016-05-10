setup_command_line
========================================

path: init/main.c
```
/* Untouched command line saved by arch-specific code. */
char __initdata boot_command_line[COMMAND_LINE_SIZE];
/* Untouched saved command line (eg. for /proc) */
char *saved_command_line;
/* Command line for parameter parsing */
static char *static_command_line;
/* Command line for per-initcall parameter parsing */
static char *initcall_command_line;

...

/*
 * We need to store the untouched command line for future reference.
 * We also need to store the touched command line since the parameter
 * parsing is performed in place, and we should allow a component to
 * store reference of name/value for future reference.
 */
static void __init setup_command_line(char *command_line)
{
    saved_command_line =
        memblock_virt_alloc(strlen(boot_command_line) + 1, 0);
    initcall_command_line =
        memblock_virt_alloc(strlen(boot_command_line) + 1, 0);
    static_command_line = memblock_virt_alloc(strlen(command_line) + 1, 0);
    strcpy(saved_command_line, boot_command_line);
    strcpy(static_command_line, command_line);
}
```

boot_command_line
----------------------------------------

boot_command_line的初始化如下所示:

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/kernel/atags_parse.c/setup_machine_tags.md
