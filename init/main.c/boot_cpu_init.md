boot_cpu_init
========================================

在多CPU的系统里，内核需要管理多个CPU，那么就需要知道系统有多少个CPU，在内核里使用cpu_present_map
位图表达有多少个CPU，每一位表示一个CPU的存在。如果是单个CPU，就是第0位设置为1。虽然系统里有多个
CPU存在，但是每个CPU不一定可以使用，或者没有初始化，在内核使用cpu_online_map位图来表示那些CPU
可以运行内核代码和接受中断处理。随着移动系统的节能需求，需要对CPU进行节能处理，比如有多个CPU
运行时可以提高性能，但花费太多电能，导致电池不耐用，需要减少运行的CPU个数，或者只需要一个CPU运行。
这样内核又引入了一个cpu_possible_map位图，表示最多可以使用多少个CPU。
在本函数里就是依次设置这三个位图的标志，让引导的CPU物理上存在，已经初始化好，最少需要运行的CPU。

当前系统的所有CPU均通过一些被声明为全局变量的掩码来进行记录，处于不同状态的CPU将对应不同的掩码。
boot_cpu_init函数设置当前CPU到online，active, present和possible掩码中。
具体行为请参考Documentation/cpu-hotplug.txt。

path: init/main.c
```
/*
 *    Activate the first processor.
 */

static void __init boot_cpu_init(void)
{
    int cpu = smp_processor_id();
    /* Mark the boot cpu "present", "online" etc for SMP and UP case */
    set_cpu_online(cpu, true);
    set_cpu_active(cpu, true);
    set_cpu_present(cpu, true);
    set_cpu_possible(cpu, true);
}
```

set_cpu_online
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/cpu.c/setup_cpu_online.md
