## ARM64 Linux 内核虚拟地址空间

32 位 CPU 的最大问题就是虚拟地址空间只有 4GB 大小。即使一些平台支持 PAE (Physical Address Extension)扩展，该问题仍然存在，
因为 PAE 主要关注物理地址的扩展问题，而不是虚拟地址。自从 64 位 CPU 问世后，情况就大为不同。AMD64 和 ARMv8 可以支持 2^64 次方的地址空间，这可是个相当大的数字。

实际上，2^64 次方太大了，Linux 内核只采用了 64 bits 的一部分（开启 CONFIG_ARM64_64K_PAGES).

可以通过源码来了解 ARM64 的内核虚拟地址空间。
在 arch/arm64/include/asm/memory.h，可以看出一些差异。首先，lowmem 区不存在了，这是因为虚拟地址很大了，可以处理 lowmem 内存，
不用再担心虚拟地址问题（但内核地址仍然有一些限制）。其次，不同内核的虚拟地址顺序改变了。

path: arch/arm64/include/asm/memory.h
```
/*
 * PAGE_OFFSET - the virtual address of the start of the linear map (top
 *		 (VA_BITS - 1))
 * KIMAGE_VADDR - the virtual address of the start of the kernel image
 * VA_BITS - the maximum number of bits for virtual addresses.
 * VA_START - the first kernel virtual address.
 */
#define VA_BITS			(CONFIG_ARM64_VA_BITS)
#define VA_START		(UL(0xffffffffffffffff) - \
	(UL(1) << VA_BITS) + 1)
#define PAGE_OFFSET		(UL(0xffffffffffffffff) - \
	(UL(1) << (VA_BITS - 1)) + 1)
#define KIMAGE_VADDR		(MODULES_END)
#define MODULES_END		(MODULES_VADDR + MODULES_VSIZE)
#define MODULES_VADDR		(VA_START + KASAN_SHADOW_SIZE)
#define MODULES_VSIZE		(SZ_128M)
```

假设VA_BITS = 39）, ARM64 上也有足够的虚拟地址了，用户空间和内核空间可以有各自的 2^39 = 512GB 的虚拟地址。
所有用户虚拟地址前25bits均为0，所有的内核虚拟地址前25bits均为 1。用户与内核之间的地址不可使用。

https://github.com/novelinux/linux-4.x.y/blob/master/arch/arm64/mm/res/linux-kernel-arm64source3.png

### 内核空间

也可以看看 arch/arm64/mm/init.c 和 arch/arm64/include/asm/pgtable.h
pkmap和fixmap不存在了，内核假设所有内存都有有效的内核虚拟地址，所以不再需要创建pkmap或者fixmap。

https://github.com/novelinux/linux-4.x.y/blob/master/arch/arm64/mm/res/linux-kernel-arm64source4.png

### 用户空间

用户空间的虚拟地址布局和 ARM32 类似，因为用户地址空间增大到了 512GB ，所以可以在 64 位 CPU 上运行更大的应用。

ARMv8 是兼容 ARM 32 位应用的，所有的 32 位 ARM 应用都可以无需修改运行在 ARMv8 上。那在 64 位内核上，32 位应用的地址布局是怎样的呢？

实际上，64 位内核运行的进程都是 64 位的。为了运行 32 位 ARM 应用，Linux 内核仍然从 init 进程创建出一个 64 位的进程，当将其用户地址空间限制到 4GB。通过这种方式，64 位的 Linux 内核可以同时运行 32 位和 64 位的应用。

```
#define TASK_SIZE_64		(UL(1) << VA_BITS)
...
/*
 * TASK_SIZE - the maximum size of a user space task.
 * TASK_UNMAPPED_BASE - the lower boundary of the mmap VM area.
 */
#ifdef CONFIG_COMPAT
#define TASK_SIZE_32		UL(0x100000000)
#define TASK_SIZE		(test_thread_flag(TIF_32BIT) ? \
				TASK_SIZE_32 : TASK_SIZE_64)
#define TASK_SIZE_OF(tsk)	(test_tsk_thread_flag(tsk, TIF_32BIT) ? \
				TASK_SIZE_32 : TASK_SIZE_64)
#else
#define TASK_SIZE		TASK_SIZE_64
#endif /* CONFIG_COMPAT */

#define TASK_UNMAPPED_BASE	(PAGE_ALIGN(TASK_SIZE / 4))

#define STACK_TOP_MAX		TASK_SIZE_64
#ifdef CONFIG_COMPAT
#define AARCH32_VECTORS_BASE	0xffff0000
#define STACK_TOP		(test_thread_flag(TIF_32BIT) ? \
				AARCH32_VECTORS_BASE : STACK_TOP_MAX)
#else
#define STACK_TOP		STACK_TOP_MAX
#endif /* CONFIG_COMPAT */
```
64 位 ARM 应用在 64 位 Linux 内核上的情况：

https://github.com/novelinux/linux-4.x.y/blob/master/arch/arm64/mm/res/linux-kernel-arm64source5.png

32 位 ARM 应用在 64 位 Linux 内核上的情况：

https://github.com/novelinux/linux-4.x.y/blob/master/arch/arm64/mm/res/linux-kernel-arm64source6.png

需要注意到，32 位应用仍然拥有 512GB 的内核虚拟地址空间，并且不与内核共享自己的 4GB 空间。
但在 ARM32 上，32 位应用只有 3GB 的地址空间。
