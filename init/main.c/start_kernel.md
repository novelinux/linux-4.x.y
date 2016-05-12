start_kernel
========================================

path: init/main.c

__mmap_switched在为内核跳转到start_kernel C函数准备运行环境:

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/kernel/head-common.S/__mmap_switched.md

asmlinkage vs __init
----------------------------------------

```
asmlinkage void __init start_kernel(void)
{
    char * command_line;
    extern const struct kernel_param __start___param[], __stop___param[];
```

asmlinkage和__init这两个宏是写内核代码的一种特定表示，一种尽可能快的思想表达，一种尽可能占用空间
少的思路。

* asmlinkage

https://github.com/novelinux/linux-4.x.y/tree/master/appendix/gcc_op/asmlinkage.md

* __init

https://github.com/novelinux/linux-4.x.y/tree/master/appendix/gcc_op/__init.md

lockdep_init
----------------------------------------

```
    /*
     * Need to run as early as possible, to initialize the
     * lockdep hash:
     */
    lockdep_init();
```

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/locking/lockdep.c/lockdep_init.md

set_task_stack_end_magic
----------------------------------------

```
    set_task_stack_end_magic(&init_task);
```

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/fork.c/set_task_stack_end_magic.md

smp_setup_processor_id
----------------------------------------

这个函数主要作用是获取当前正在执行初始化的处理器ID.

```
    smp_setup_processor_id();
```

### ARM

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/kernel/setup.c/smp_setup_processor_id.md

debug_objects_early_init
----------------------------------------

这个函数主要作用是对调试对象进行早期的初始化，其实就是HASH锁和静态对象池进行初始化。

```
    debug_objects_early_init();
```

### aries

CONFIG_DEBUG_OBJECTS没有配置的话改函数是空实现.

```
# CONFIG_DEBUG_OBJECTS is not set
```

boot_init_stack_canary
----------------------------------------

```
    /*
     * Set up the the initial canary ASAP:
     */
    boot_init_stack_canary();
```

### ARM

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/include/asm/stackprotector.h/boot_init_stack_canary.md

cgroup_init_early
----------------------------------------

```
    cgroup_init_early();
```

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/cgroup.c/cgroup_init_early.md

local_irq_disable
----------------------------------------

这个函数主要作用是关闭当前CPU的所有中断响应。在ARM体系里主要就是对CPSR寄存器进行操作。

```
    local_irq_disable();

    early_boot_irqs_disabled = true;
    /*
    * Interrupts are still disabled. Do necessary setups, then
    * enable them
    */
```

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/irqflags.h/local_irq_disable.md

boot_cpu_init
----------------------------------------

```
    boot_cpu_init();
```

https://github.com/novelinux/linux-4.x.y/tree/master/init/main.c/boot_cpu_init.md

page_address_init
----------------------------------------

```
    page_address_init(); // 空实现.
```

linux_banner
----------------------------------------

```
    // 主要作用是在输出终端上显示版本信息、编译的电脑用户名称、编译器版本、编译时间。
    pr_notice("%s", linux_banner);
```

setup_arch
----------------------------------------

这个函数主要作用是对内核架构进行初始化。再次获取CPU类型和系统架构，分析引导程序传入的命令行参数，
进行页面内存初始化，处理器初始化，中断早期初始化等等。

```
    setup_arch(&command_line);
```

### ARM

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/kernel/setup.c/setup_arch.md

mm_init_cpumask
----------------------------------------

```
    mm_init_cpumask(&init_mm);
```

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/mm_types.h/mm_init_cpumask.md

setup_command_line
----------------------------------------

这个函数主要作用是保存命令行，以便后面可以使用。

```
    setup_command_line(command_line);
```

https://github.com/novelinux/linux-4.x.y/tree/master/init/main.c/setup_command_line.md

setup_nr_cpu_ids
----------------------------------------

```
    setup_nr_cpu_ids();
```

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/smp.c/setup_nr_cpu_ids.md

setup_per_cpu_areas
----------------------------------------

setup_per_cpu_areas()函数给每个CPU分配内存，并拷贝.data.percpu段的数据。为系统中的每个
CPU的per_cpu变量申请空间。

```
    setup_per_cpu_areas();
```

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/percpu.c/setup_per_cpu_areas.md

smp_prepare_boot_cpu
----------------------------------------

如果是SMP环境，则设置boot CPU的一些数据。在引导过程中使用的CPU称为boot CPU.

```
    smp_prepare_boot_cpu();    /* arch-specific boot-cpu hooks */
```

### ARM

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/kernel/smp.c/smp_prepare_boot_cpu.c

build_all_zonelists
----------------------------------------

这个函数主要作用是初始化所有内存管理节点列表，以便后面进行内存管理初始化。

```
    build_all_zonelists(NULL, NULL);
```

page_alloc_init
----------------------------------------

这个函数主要作用是设置内存页分配通知器。

```
    page_alloc_init();
```

parse_early_param
----------------------------------------

解析内核参数.

```
    printk(KERN_NOTICE "Kernel command line: %s\n", boot_command_line);
    parse_early_param();
    parse_args("Booting kernel", static_command_line, __start___param,
           __stop___param - __start___param,
           0, 0, &unknown_bootoption);
```

https://github.com/novelinux/linux-4.x.y/tree/master/init/main.c/parse_early_param.md

jump_label_init
----------------------------------------

```
    jump_label_init();
```

setup_log_buf
----------------------------------------

```
    /*
     * These use large bootmem allocations and must precede
     * kmem_cache_init()
     */
    setup_log_buf(0);
```

pidhash_init
----------------------------------------

这个函数是进程ID的HASH表初始化，这样可以提供通PID进行高效访问进程结构的信息。
LINUX里共有四种类型的PID，因此就有四种HASH表相对应。

```
    pidhash_init();
```

vfs_caches_init_early
----------------------------------------

初始化VFS的两个重要数据结构dcache和inode的缓存。

```
    vfs_caches_init_early();
```

sort_main_extable
----------------------------------------

把编译期间,kbuild设置的异常表,也就是__start___ex_table和__stop___ex_table之中的所有元素进行排序

```
    sort_main_extable();
```

trap_init
----------------------------------------

初始化中断向量表,在ARM系统里是空函数，没有任何的初始化。

```
    trap_init();
```

mm_init
----------------------------------------

这个函数是标记那些内存可以使用，并且告诉系统有多少内存可以使用，当然是除了内核使用的内存以外。

```
    mm_init();
```

https://github.com/novelinux/linux-4.x.y/tree/master/init/main.c/mm_init.md

sched_init
----------------------------------------

这个函数主要作用是对进程调度器进行初始化，比如分配调度器占用的内存，初始化任务队列，设置当前任务
的空线程，当前任务的调度策略为CFS调度器, 核心进程调度器初始化，调度器的初始化的优先级要高于任何
中断的建立，并且初始化进程0，即idle进程，但是并没有设置idle进程的NEED_RESCHED标志，所以还会继续
完成内核初始化剩下的事情。这里仅仅为进程调度程序的执行做准备。它所做的具体工作是调用init_bh
函数(kernel/softirq.c)把timer,tqueue,immediate三个人物队列加入下半部分的数组

```
    /*
     * Set up the scheduler prior starting any interrupts (such as the
     * timer interrupt). Full topology setup happens at smp_init()
     * time - but meanwhile we still have a functioning scheduler.
     */
    sched_init();
```

preempt_disable
----------------------------------------

这个函数主要作用是关闭优先级调度。由于每个进程任务都有优先级，目前系统还没有完全初始化，还不能
打开优先级调度。

```
    /*
     * Disable preemption - early bootup scheduling is extremely
     * fragile until we cpu_idle() for the first time.
     */
    preempt_disable();
```

local_irq_disable
----------------------------------------

这段代码主要判断是否过早打开中断，如果是这样，就会提示，并把中断关闭。

```
    if (!irqs_disabled()) {
        printk(KERN_WARNING "start_kernel(): bug: interrupts were "
                "enabled *very* early, fixing it\n");
        local_irq_disable();
    }
```

idr_init_cache
----------------------------------------

这个函数是创建IDR机制的内存缓存对象。所谓的IDR就是整数标识管理机制（integerIDmanagement）。
引入的主要原因是管理整数的ID与对象的指针的关系，由于这个ID可以达到32位，也就是说，如果使用
线性数组来管理，那么分配的内存太大了；如果使用线性表来管理，又效率太低了，所以就引用IDR管理
机制来实现这个需求。

```
    idr_init_cache();
```

perf_event_init
----------------------------------------

```
    perf_event_init();
```

rcu_init
----------------------------------------

这个函数是初始化直接读拷贝更新的锁机制。RCU主要提供在读取数据机会比较多，但更新比较的少的场合，
这样减少读取数据锁的性能低下的问题。

Read-Copy-Update的初始化
RCU机制是Linux2.6之后提供的一种数据一致性访问的机制，从RCU（read-copy-update）的名称上看，
我们就能对他的实现机制有一个大概的了解，在修改数据的时候，首先需要读取数据，然后生成一个副本，
对副本进行修改，修改完成之后再将老数据update成新的数据，此所谓RCU.

```
    rcu_init();
```

radix_tree_init
----------------------------------------

Linux使用radix树来管理位于文件系统缓冲区中的磁盘块，radix树是trie树的一种.
这个函数是初始化radix树，radix树基于二进制键值的查找树。

```
    radix_tree_init();
```

early_irq_init
----------------------------------------

early_irq_init 则对数组中每个成员结构进行初始化,例如, 初始每个中断源的中断号.其他的函数基本为空.

```
    /* init some links before init_ISA_irqs() */
    early_irq_init();
```

init_IRQ
----------------------------------------

初始化IRQ中断和终端描述符.初始化系统中支持的最大可能的中断描述结构struct irqdesc
变量数组irq_desc[NR_IRQS],把每个结构变量irq_desc[n]都初始化为预先定义好的中断
描述结构变量bad_irq_desc,并初始化该中断的链表表头成员结构变量pend.

```
    init_IRQ();
```

prio_tree_init
----------------------------------------

这个函数是初始化优先搜索树，主要用在内存反向搜索方面。

```
    prio_tree_init();
```

init_timers
----------------------------------------

这个函数是主要初始化引导CPU的时钟相关的数据结构，注册时钟的回调函数，当时钟到达时可以回调
时钟处理函数，最后初始化时钟软件中断处理。

```
    init_timers();
```

hrtimers_init
----------------------------------------

对高精度时钟进行初始化.

```
    hrtimers_init();
```

softirq_init
----------------------------------------

这个函数是初始化软件中断，软件中断与硬件中断区别就是中断发生时，软件中断是使用线程来监视中断信号，
而硬件中断是使用CPU硬件来监视中断。

```
    softirq_init();
```

timekeeping_init
----------------------------------------

这个函数是初始化系统时钟计时，并且初始化内核里与时钟计时相关的变量。

```
    timekeeping_init();
```

time_init
----------------------------------------

初始化系统时间，检查系统定时器描述结构struct sys_timer全局变量system_timer是否为空，
如果为空将其指向dummy_gettimeoffset()函数。

```
    time_init();
```

profile_init
----------------------------------------

profile只是内核的一个调试性能的工具,这个可以通过menuconfig中的Instrumentation Support->profile.

```
    profile_init();
```

call_function_init
----------------------------------------

```
    call_function_init();
```

local_irq_enable
----------------------------------------

这个函数是打开本CPU的中断，也即允许本CPU处理中断事件，在这里打开引CPU的中断处理。如果有多核心，
别的CPU还没有打开中断处理。

```
    // 这两行代码是提示中断是否过早地打开。
    if (!irqs_disabled())
        printk(KERN_CRIT "start_kernel(): bug: interrupts were "
                 "enabled early\n");
    early_boot_irqs_disabled = false;
    local_irq_enable();
```

gfp_allowd_mask
----------------------------------------


```
    /* Interrupts are enabled now so all GFP allocations are safe. */
    gfp_allowed_mask = __GFP_BITS_MASK;
```

kmem_cache_init_late
----------------------------------------

memory cache的初始化.

```
    kmem_cache_init_late();
```

console_init
----------------------------------------

初始化控制台以显示printk的内容，在此之前调用的printk，只是把数据存到缓冲区里，只有在这个函数调用
后，才会在控制台打印出内容该函数执行后可调用printk()函数将log_buf中符合打印级别要求的系统信息
打印到控制台上。

```
    /*
     * HACK ALERT! This is early. We're enabling the console before
     * we've done PCI setups etc, and console_init() must be aware of
     * this. But we do want output early, in case something goes wrong.
     */
    console_init();
    if (panic_later)
        panic(panic_later, panic_param);
```

lockdep_info
----------------------------------------

这个函数是打印锁的依赖信息，用来调试锁。通过这个函数可以查看目前锁的状态，以便可以发现那些锁产生
死锁，那些锁使用有问题。

```
    lockdep_info();
```

locking_selftest
----------------------------------------

这个函数是用来测试锁的API是否使用正常，进行自我测试。比如测试自旋锁、读写锁、一般信号量和
读写信号量。

```
    /*
     * Need to run this when irqs are enabled, because it wants
     * to self-test [hard/soft]-irqs on/off lock inversion bugs
     * too:
     */
    locking_selftest();
```

CONFIG_BLK_DEV_INITRD
----------------------------------------

```
#ifdef CONFIG_BLK_DEV_INITRD
    if (initrd_start && !initrd_below_start_ok &&
        page_to_pfn(virt_to_page((void *)initrd_start)) < min_low_pfn) {
        printk(KERN_CRIT "initrd overwritten (0x%08lx < 0x%08lx) - "
            "disabling it.\n",
            page_to_pfn(virt_to_page((void *)initrd_start)),
            min_low_pfn);
        initrd_start = 0;
    }
#endif
```

page_cgroup_init
----------------------------------------

page_cgroup_init()这个函数是容器组的页面内存分配。

```
    page_cgroup_init();
```

debug_objects_mem_init
----------------------------------------

```
    debug_objects_mem_init();
```

kmemleak_init
----------------------------------------

这个函数是设置内存分配是否需要输出调试信息，如果调用这个函数，当分配内存时，不会输出一些相关的信息

```
    kmemleak_init();
```

setup_per_cpu_pageset
----------------------------------------

这个函数是创建每个CPU的高速缓存集合数组。因为每个CPU都不定时需要使用一些页面内存和释放页面内存，
为了提高效率，就预先创建一些内存页面作为每个CPU的页面集合。

```
    setup_per_cpu_pageset();
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/setup_per_cpu_pageset.md

numa_policy_init
----------------------------------------

这个函数是初始化NUMA的内存访问策略。所谓NUMA，它是NonUniform Memory AccessAchitecture的缩写，
主要用来提高多个CPU访问内存的速度。因为多个CPU访问同一个节点的内存速度远远比访问多个节点的
速度来得快。

```
    numa_policy_init();
```

late_time_init
----------------------------------------

这段代码是主要运行时钟相关后期的初始化功能。

```
    if (late_time_init)
        late_time_init();
```

sched_clock_init
----------------------------------------

这个函数是主要计算CPU需要校准的时间，这里说的时间是CPU执行时间。如果是引导CPU，这个函数计算出来
的校准时间是不需要使用的，主要使用在非引导CPU上，因为非引导CPU执行的频率不一样,导致时间计算不准确

```
    sched_clock_init();
```

calibrate_delay
----------------------------------------

```
    calibrate_delay();
```

pidmap_init
----------------------------------------

这个函数是进程位图初始化，一般情况下使用一页来表示所有进程占用情况。

```
    pidmap_init();
```

anon_vma_init
----------------------------------------

这个函数是初始化反向映射的匿名内存，提供反向查找内存的结构指针位置，快速地回收内存。

```
    anon_vma_init();
```

CONFIG_X86
----------------------------------------

这段代码是初始化EFI的接口，并进入虚拟模式。EFI是ExtensibleFirmware Interface的缩写，就是INTEL
公司新开发的BIOS接口。

```
#ifdef CONFIG_X86
    if (efi_enabled)
        efi_enter_virtual_mode();
#endif
```

thread_info_cache_init
----------------------------------------

这个函数是线程信息的缓存初始化.

```
    thread_info_cache_init();
```

cred_init
----------------------------------------

```
    cred_init();
```

fork_init
----------------------------------------

这个函数是根据当前物理内存计算出来可以创建进程（线程）的数量，并进行进程环境初始化。

```
    fork_init(totalram_pages);
```

proc_caches_init
----------------------------------------

这个函数是进程缓存初始化。

```
    proc_caches_init();
```

buffer_init
----------------------------------------

这个函数是初始化文件系统的缓冲区，并计算最大可以使用的文件缓存。

```
    buffer_init();
```

key_init
----------------------------------------

这个函数是初始化安全键管理列表和结构。

```
    key_init();
```

security_init
----------------------------------------

这个函数是初始化安全管理框架，以便提供访问文件／登录等权限。

```
    security_init();
```

dbg_late_init
----------------------------------------

```
    dbg_late_init();
```

vfs_caches_init
----------------------------------------

这个函数是虚拟文件系统进行缓存初始化，提高虚拟文件系统的访问速度。

```
    vfs_caches_init(totalram_pages);
```

signals_init
----------------------------------------

这个函数是初始化信号队列缓存。

```
    signals_init();
```

page_writeback_init
----------------------------------------

```
    /* rootfs populating might need page-writeback */
    page_writeback_init();
```

proc_root_init
----------------------------------------

这个函数是初始化系统进程文件系统，主要提供内核与用户进行交互的平台，方便用户实时查看进程的信息。

```
#ifdef CONFIG_PROC_FS
    proc_root_init();
#endif
```

cgroup_init
----------------------------------------

这个函数是初始化进程控制组，主要用来为进程和其子程提供性能控制.比如限定这组进程的CPU使用率为20％。

```
    cgroup_init();
```

cpuset_init
----------------------------------------

这个函数是初始化CPUSET，CPUSET主要为控制组提供CPU和内存节点的管理的结构。

```
    cpuset_init();
```

taskstats_init_early
----------------------------------------

这个函数是初始化任务状态相关的缓存、队列和信号量。任务状态主要向用户提供任务的状态信息。

```
    taskstats_init_early();
```

delayacct_init
----------------------------------------

这个函数是初始化每个任务延时计数。当一个任务等CPU运行，或者等IO同步时，都需要计算等待时间。

```
    delayacct_init();
```

check_bugs
----------------------------------------

这个函数是用来检查CPU配置、FPU等是否非法使用不具备的功能。

```
    check_bugs();
```

acpi_early_init
----------------------------------------

这个函数是初始化ACPI电源管理。高级配置与能源接口(ACPI)ACPI规范介绍ACPI能使软、硬件、
操作系统（OS），主机板和外围设备，依照一定的方式管理用电情况，系统硬件产生的Hot-Plug事件，
让操作系统从用户的角度上直接支配即插即用设备，不同于以往直接通过基于BIOS 的方式的管理。

```
    acpi_early_init(); /* before LAPIC and SMP init */
```

sfi_init_late
----------------------------------------

```
    sfi_init_late();
```

ftrace_init
----------------------------------------

这个函数是初始化内核跟踪模块，ftrace的作用是帮助开发人员了解Linux 内核的运行时行为，以便进行故障
调试或性能分析。

```
    ftrace_init();
```

rest_init
----------------------------------------

这个函数是后继初始化，主要是创建内核线程init，并运行。

```
    /* Do the rest non-__init'ed, we're now alive */
    rest_init();
}
```

https://github.com/novelinux/linux-4.x.y/tree/master/init/main.c/rest_init.md
