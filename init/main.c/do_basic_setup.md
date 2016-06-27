do_basic_setup
========================================

path: init/main.c
```
/*
 * Ok, the machine is now initialized. None of the devices
 * have been touched yet, but the CPU subsystem is up and
 * running, and memory and process management works.
 *
 * Now we can finally start doing some real work..
 */
static void __init do_basic_setup(void)
{
    cpuset_init_smp();
    shmem_init();
    driver_init();
    init_irq_proc();
    do_ctors();
    usermodehelper_enable();
```

do_initcalls
----------------------------------------

```
    do_initcalls();
```

https://github.com/novelinux/linux-4.x.y/tree/master/init/main.c/do_initcalls.md

random_int_secret_init
----------------------------------------

```
    random_int_secret_init();
}
```