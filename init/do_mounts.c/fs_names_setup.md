fs_names_setup
========================================

path: init/do_mounts.c
```
static int __init fs_names_setup(char *str)
{
    root_fs_names = str;
    return 1;
}

__setup("rootfstype=", fs_names_setup);
```