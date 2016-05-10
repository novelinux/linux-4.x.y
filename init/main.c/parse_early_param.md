parse_early_param
========================================

path: init/main.c
```
/* Untouched command line saved by arch-specific code. */
char __initdata boot_command_line[COMMAND_LINE_SIZE];

...

/* Arch code calls this early on, or if not, just before other parsing. */
void __init parse_early_param(void)
{
    static int done __initdata;
    static char tmp_cmdline[COMMAND_LINE_SIZE] __initdata;

    if (done)
        return;

    /* All fall through to do_early_param. */
    strlcpy(tmp_cmdline, boot_command_line, COMMAND_LINE_SIZE);
    parse_early_options(tmp_cmdline);
    done = 1;
}
```

我们假设boot_command_line为如下信息，其余的类似:

```
"root=/dev/sda2 panic=1 rootfstype=ext4 rw init=/bin/bash"
```

parse_early_options
----------------------------------------

```
void __init parse_early_options(char *cmdline)
{
    parse_args("early options", cmdline, NULL, 0, 0, 0, do_early_param);
}
```

parse_args
----------------------------------------

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/kernel/params.c/parse_args.md

do_early_param
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/init/main.c/do_early_param.md
