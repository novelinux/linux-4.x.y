kernel_init_freeable
========================================

path: init/main.c
```
static noinline void __init kernel_init_freeable(void)
{
    /*
     * Wait until kthreadd is all set-up.
     */
    wait_for_completion(&kthreadd_done);

    /* Now the scheduler is fully set up and can do blocking allocations */
    gfp_allowed_mask = __GFP_BITS_MASK;

    /*
     * init can allocate pages on any node
     */
    set_mems_allowed(node_states[N_MEMORY]);
    /*
     * init can run on any cpu.
     */
    set_cpus_allowed_ptr(current, cpu_all_mask);

    cad_pid = task_pid(current);

    smp_prepare_cpus(setup_max_cpus);

    do_pre_smp_initcalls();
    lockup_detector_init();

    smp_init();
    sched_init_smp();
```

do_basic_setup
----------------------------------------

```
    do_basic_setup();
```

https://github.com/novelinux/linux-4.x.y/tree/master/init/main.c/do_basic_setup.md

console
----------------------------------------

```
    /* Open the /dev/console on the rootfs, this should never fail */
    if (sys_open((const char __user *) "/dev/console", O_RDWR, 0) < 0)
        pr_err("Warning: unable to open an initial console.\n");

    (void) sys_dup(0);
    (void) sys_dup(0);
    /*
     * check if there is an early userspace init.  If yes, let it do all
     * the work
     */

    if (!ramdisk_execute_command)
        ramdisk_execute_command = "/init";

    if (sys_access((const char __user *) ramdisk_execute_command, 0) != 0) {
        ramdisk_execute_command = NULL;
        prepare_namespace();
    }

    /*
     * Ok, we have completed the initial bootup, and
     * we're essentially up and running. Get rid of the
     * initmem segments and start the user-mode stuff..
     *
     * rootfs is available now, try loading the public keys
     * and default modules
     */

    integrity_load_keys();
    load_default_modules();
}
```