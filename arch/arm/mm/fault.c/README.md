Page Fault
========================================

在ARM架构下，TLB miss后的工作绝大多数情况是由hardwarepage table walk完成，
特殊情况下hardware page table walk可以被关闭，此时发生TLB miss后CPU就会
产生一个translation fault，剩下的工作由OS接管，完成对于translation fault的异常处理。

默认情况下，发生TLB miss后，hardware page table walk自动启动开始扫描内存中的
pagetable，若找到相应PTE（page table entry），则自动完成TLB entry的重填工作；
如果找不到，则发出一个page fault异常，然后OS接管处理page fault。内核中有
do_page_fault函数，该函数从硬盘中调换页面进内存，更新页表，然后重新执行发生
TLB miss的那条指令，hardware page table walk重新执行，完成TLB重填的工作。

这里关心的是关闭hardware pagetable walk后，再发生TLB miss后的处理例程。
如果发生这种情况，ARM CPU会发出一个translation fault（If translation
table walksare disabled, for example, PD0 or EPD0 is set to 1 for TTBR0,
 or PD1 or EPD1 isset to 1 for TTBR1, the processor returns a
Translation fault.见cortex-A15TRM p 5-5）。OS处理该异常的流程如下:

__vector_start
----------------------------------------

首先发生translation fault后，CPU会发出一个abort异常，然后跳转到该异常
地址处（以发生指令预取中止异常为例，跳转到0x00000010）去执行，该地址处
存放的是一个跳转指令:

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/kernel/entry-armv.S/__vector_start.md
