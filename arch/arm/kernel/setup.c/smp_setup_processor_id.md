smp_setup_processor_id
========================================

这个函数主要作用是获取当前正在执行初始化的处理器ID。smp_setup_processor_id()函数每次都要中断CPU
去获取ID，这样效率比较低。由于单处理器的频率已经慢慢变得不能再高了，那么处理器的计算速度还要提高，
还有别的办法吗？这样自然就想到多个处理器的技术。这就好比物流公司，有很多货只让一辆卡车在高速公路
上来回运货，这样车的速度已经最快了，运的货就一定了，不可能再多得去。那么物流公司想提高运货量，那
只能多顾用几台卡车了，这样运货量就比以前提高了。处理器的制造厂家自然也想到这样的办法，就是几个
处理器放到一起，这样就可以提高处理速度。接着下来的问题又来，那么这几个处理器怎么样放在一起，
成本最低，性能最高。考虑到这样的一种情况，处理器只有共享主内存、总线、外围设备，其它每个处理器是
独立的，这样可以省掉很多外围硬件成本。当然所有这些处理器还共享一个操作系统，这样的结构就叫做
对称多处理器（SymmetricalMulti-Processing）。在对称多处理器系统里，所有处理器只有在初始化阶段
处理有主从之分，到系统初始化完成之后，大家是平等的关系，没有主从处理器之分了。在内核里所有以
smp开头的函数都是处理对称多处理器相关内容的，对称多处理器与单处理器在操作系统里，主要区别是
引导处理器与应用处理器，每个处理器不同的缓存，中断协作，锁的同步。因此，在内核初始化阶段需要区分，
在与缓存同步数据需要处理，在中断方面需要多个处理协作执行，在多个进程之间要做同步和通讯。如果内核
只是有单处理器系统，smp_setup_processor_id()函数是是空的，不必要做任保的处理。

path: arch/arm/kernel/setup.c
```
u32 __cpu_logical_map[NR_CPUS] = { [0 ... NR_CPUS-1] = MPIDR_INVALID };

void __init smp_setup_processor_id(void)
{
    int i;
    u32 mpidr = is_smp() ? read_cpuid_mpidr() & MPIDR_HWID_BITMASK : 0;
    u32 cpu = MPIDR_AFFINITY_LEVEL(mpidr, 0);

    cpu_logical_map(0) = cpu;
    for (i = 1; i < nr_cpu_ids; ++i)
        cpu_logical_map(i) = i == cpu ? 0 : i;

    /*
     * clear __my_cpu_offset on boot CPU to avoid hang caused by
     * using percpu variable early, for example, lockdep will
     * access percpu variable inside lock_release
     */
    set_my_cpu_offset(0);

    pr_info("Booting Linux on physical CPU 0x%x\n", mpidr);
}
```

注意: 与smp_processor_id()函数区别，这两个函数都是获取多处理器的ID，为什么会需要两个函数呢？
其实这里有一个差别的，smp_setup_processor_id()函数可以不调用setup_arch()初始化函数就可以使用，
而smp_processor_id()函数是一定要调用setup_arch()初始化函数后，才能使用。smp_setup_processor_id()
函数是直接获取对称多处理器的ID，而smp_processor_id()函数是获取变量保存的处理器ID，因此一定要调用
初始化函数。由于smp_setup_processor_id()函数不用调用初始化函数，可以放在内核初始化start_kernel
函数的最前面使用，而函数smp_processor_id()只能放到setup_arch()函数调用的后面使用了。