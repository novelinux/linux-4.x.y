kernel_init
========================================

kernel_init_freeable
----------------------------------------

path: init/main.c
```
static int __ref kernel_init(void *unused)
{
    int ret;

    kernel_init_freeable();
```

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/init/main.c/kernel_init_freeable.md

通用设置
----------------------------------------

```
    /* need to finish all async __init code before freeing the memory */
    async_synchronize_full();
    free_initmem();
    mark_rodata_ro();
    system_state = SYSTEM_RUNNING;
    numa_default_policy();

    flush_delayed_fput();
```

try_to_run_init_process
----------------------------------------

```
    if (ramdisk_execute_command) {
        ret = run_init_process(ramdisk_execute_command);
        if (!ret)
            return 0;
        pr_err("Failed to execute %s (error %d)\n",
               ramdisk_execute_command, ret);
    }

    /*
     * We try each of these until one succeeds.
     *
     * The Bourne shell can be used instead of init if we are
     * trying to recover a really broken machine.
     */
    if (execute_command) {
        ret = run_init_process(execute_command);
        if (!ret)
            return 0;
#ifndef CONFIG_INIT_FALLBACK
        panic("Requested init %s failed (error %d).",
              execute_command, ret);
#else
        pr_err("Failed to execute %s (error %d).  Attempting defaults...\n",
               execute_command, ret);
#endif
    }
    if (!try_to_run_init_process("/sbin/init") ||
        !try_to_run_init_process("/etc/init") ||
        !try_to_run_init_process("/bin/init") ||
        !try_to_run_init_process("/bin/sh"))
        return 0;

    panic("No working init found.  Try passing init= option to kernel. "
          "See Linux Documentation/init.txt for guidance.");
}
```

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/init/main.c/try_to_run_init_process.md
