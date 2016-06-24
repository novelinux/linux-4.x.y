root_dev_setup
========================================

path: init/do_mounts.c
```
static int __init root_dev_setup(char *line)
{
    strlcpy(saved_root_name, line, sizeof(saved_root_name));
    return 1;
}

__setup("root=", root_dev_setup);
```
