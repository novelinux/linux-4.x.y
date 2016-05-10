do_early_param
========================================

boot_command_line存储的指定给kernel的内核参数会由do_early_param函数来解析，
并调用相关函数来实现对应功能.

path: init/main.c
```
/* Check for early params. */
static int __init do_early_param(char *param, char *val, const char *unused)
{
    const struct obs_kernel_param *p;

    for (p = __setup_start; p < __setup_end; p++) {
        if ((p->early && parameq(param, p->str)) ||
            (strcmp(param, "console") == 0 &&
             strcmp(p->str, "earlycon") == 0)
        ) {
            if (p->setup_func(val) != 0)
                pr_warn("Malformed early option '%s'\n", param);
        }
    }
    /* We accept everything at this stage. */
    return 0;
}
```

struct obs_kernel_param
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/init.h/struct_obs_kernel_param.md

__setup_start vs __setup_end
----------------------------------------

__setup_start和setup_end在vmlinux.lds.h中定义，显然所有名为.init.setup的段
都包含在其中.

path: include/asm-generic/vmlinux.lds.h
```
#define INIT_SETUP(initsetup_align)					\
		. = ALIGN(initsetup_align);				\
		VMLINUX_SYMBOL(__setup_start) = .;			\
		*(.init.setup)						\
		VMLINUX_SYMBOL(__setup_end) = .;
```

path: arch/arm/kernel/vmlinux.lds.S
```
	.init.data : {
                ...
		INIT_SETUP(16)
                ...
	}
```

实例
----------------------------------------

例如,"root=/dev/sda2".

```
do_early_param (param=0xc04c3410 <tmp_cmdline.42662> "root", val=0xc04c3415 <tmp_cmdline.42662+5> "/dev/sda2", unused=0xc0422ed8 "early options", arg=0x0 <__vectors_start>)
    at /home/liminghao/big/leeminghao/yudatun-qemu/kernel/linux-4.3/init/main.c:421
421    for (p = __setup_start; p < __setup_end; p++) {
```

对应的setup函数如下所示:

path: init/do_mounts.c
```
static int __init root_dev_setup(char *line)
{
        strlcpy(saved_root_name, line, sizeof(saved_root_name));
        return 1;
}

__setup("root=", root_dev_setup);
```

对应的__setup宏实现参考:

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/init.h/struct_obs_kernel_param.md
