head.S 内核解压
========================================

在bootloader加载完内核之后，即将跳转到内核代码执行时，必须关闭MMU和cache。这时候都是使用物理地址.

https://github.com/leeminghao/doc-linux/blob/master/bootloader/lk/apps/aboot/aboot_c/boot_linux.md

相关地址值
----------------------------------------

https://github.com/torvalds/linux/blob/bdec41963890f8ed9ad89f8b418959ab3cdc2aa3/Documentation/arm/Porting

* ZTEXTADDR:

  运行时候zImage的起始地址，即kernel解压代码的地址。这里没有虚拟地址的概念，因为没有开启
  MMU，所以这个地址是物理内存的地址。解压代码不一定需要载入RAM才能运行，在FLASH或者其他可寻址的
  媒体上都可以运行。

* ZBSSADDR:

  解压代码的BSS段的地址，这里也是物理地址。

* ZRELADDR:

  这个是kernel解压以后存放的内存物理地址，解压代码执行完成以后会跳到这个地址执行kernel的启动，
  这个地址和后面kernel运行时候的虚拟地址满足：__virt_to_phys(TEXTADDR) = ZRELADDR。

* INITRD_PHYS:

  Initial Ram Disk存放在内存中的物理地址，这里就是我们的ramdisk.img。

* INITRD_VIRT:

  Initial Ram Disk运行时候虚拟地址。

* PARAMS_PHYS:

   内核启动的初始化参数在内存上的物理地址。

过程
----------------------------------------

在zImage的生成过程中,是把arch/arm/boot/compressed/head.S和解压代码misc.c，decompress.c加在
压缩内核(piggy.gzip.o)的最前面最终生成vmlinux然后使用objcopy生成的原始二进制文件zImage的，
那么它的启动过程就是从这个head.S开始的，并且如果代码从RAM运行的话，是与位置无关的，可以
加载到内存的任何地方.

* head.o是内核的头部文件，负责初始设置;
* misc.o将主要负责内核的解压工作，它在head.o之后；
* piggy.gzip.o是一个中间文件，其实是一个压缩的内核(kernel/vmlinux).

例如在使用lk来加载内核是将kernel加载到地址0x80208000处.该地址一般由boot_img_hdr(boot.img
的header结构体)中指定.详情参考:

https://github.com/leeminghao/doc-linux/tree/master/bootloader/lk/README.md

对应的内存布局如下：

https://github.com/leeminghao/doc-linux/blob/master/arch/arm/msm8960/memory_layout.md

在bootloader加载kernel映像zImage执行的过程我们知道,第一条指定即指向了head.S中start标志
开始代码，如下所示:

path: arch/arm/boot/compressed/head.S

过程
----------------------------------------

head.S会做些什么工作?

* 对于各种Arm CPU的DEBUG输出设定，通过定义宏来统一操作.

* 设置kernel开始和结束地址，保存architecture ID 和 atags 地址.

* 如果在ARM2以上的CPU中，用的是普通用户模式，则升到超级用户模式，然后关中断.

* 分析LC0结构delta offset，判断是否需要重载内核地址(r0存入偏移量，判断r0是否为零).

* 需要重载内核地址，将r0的偏移量加到BSS region和GOT table中的每一项。对于位置无关的代码，
  程序是通过GOT表访问全局数据目标的，也就是说GOT表中记录的是全局数据目标的绝对地址，所以
  其中的每一项也需要重载。

* 清空bss堆栈空间，建立C程序运行需要的缓存

* 这时r2是缓存的结束地址，r4是kernel的最后执行地址，r5是kernel境象文件的开始地址

* 用文件misc.c的函数decompress_kernel()，解压内核于缓存结束的地方(r2地址之后)。

为了更清楚的了解解压的动态过程。我们用图表的方式描述下代码的搬运解压过程。然后再针对中间的
一些关键过程阐述。zImage在内存中的初始地址为0x80208000(这个地址由bootloader决定，位置不固定)
lk会将zImage镜像copy到sdram的0x80208000位置处。此时为初始状态，这里称为状态1。

1.初始状态

```
｜.text   ｜  0x80208000开始，包含piggydata段（即压缩的内核段）
｜.got    ｜
｜.data   ｜
｜.bss    ｜
｜.stack  ｜   4K大小
```

2.head.S调用misc.c中的decompress_kernel刚解压完内核后,内存中的各段位置如下，状态2

```
.text              ｜ 0x80208000开始，包含piggydata段（即压缩的内核段）
. got              ｜
. data             ｜
.bss               ｜
.stack             ｜4K大小
解压函数所需缓冲区 ｜64K大小
解压后的内核代码   ｜小于4M
```

3.当如果head.S中有代码搬运工作时，即出现overwrite时，内存中的各段位置如下，此时会将head.S
中的部分代码重定位，状态3

```
.text                        ｜0x80208000开始，包含piggydata段（即压缩的内核段）
. got                        ｜
. data                       ｜
.bss                         ｜
.stack                       ｜ 4K大小
解压函数所需缓冲区           ｜ 64K大小
解压后的内核代码             ｜ 小于4M
head.S中的部分重定位代码代码 ｜ reloc_start至reloc_end
```

4.跳转到重定位后的reloc_start处，由reloc_start至reloc_end的代码复制解压后的内核代码到
0x80208000处，并调用call_kernel跳转到0x80208000处执行。

解压后的内核  ｜  0x80208000开始

注意:

* bootloader将IMG载入RAM以后，并跳到zImage的地址开始解压的时候，这里就涉及到另外一个重要的参数，
  那就是ZRELADDR，就是解压后的kernel应该放在哪。这个参数一般都是arch/arm/mach-xxx下面的
  Makefile.boot来提供的；

path: arch/arm/msm-8960/Makefile.boot

```
# MSM8960
   zreladdr-$(CONFIG_ARCH_MSM8960)	:= 0x80208000
```

* 另外现在解压的代码head.S和misc.c一般都会以PIC的方式来编译，这样载入RAM在任何地方都可以运行，
  这里涉及到两次冲定位的过程，基本上这个重定位的过程在ARM上都是差不多一样的。

问题:
----------------------------------------

### 问题1

zImage是如何知道自己最后的运行地址是0x80208000的?

path: arch/arm/mach-msm/Makefile.boot
```
# MSM8960
   zreladdr-$(CONFIG_ARCH_MSM8960)	:= 0x80208000 这个就是zImage的运行地址了
```

path: arch/arm/boot/Makefile
```
# Note: the following conditions must always be true:
#   ZRELADDR == virt_to_phys(PAGE_OFFSET + TEXT_OFFSET)
#   PARAMS_PHYS must be within 4MB of ZRELADDR
#   INITRD_PHYS must be in RAM
ZRELADDR    := $(zreladdr-y)
```

path: arch/arm/boot/compressed/Makefile

```
# Supply ZRELADDR to the decompressor via a linker symbol.
ifneq ($(CONFIG_AUTO_ZRELADDR),y)
LDFLAGS_vmlinux += --defsym zreladdr=$(ZRELADDR)
endif
```
内核就是用这种方式让代码知道最终运行的位置的

我们可以提取出来看一下:

path: arch/arm/boot/compressed/vmlinux
```
$ objdump -t vmlinux | grep -i zreladdr
80208000 g       *ABS*    00000000 zreladdr
```

### 问题2

调用decompress_kernel函数时，其4个参数是什么值及物理含义？

path: arch/arm/boot/compressed/head.S
```
/*
 * The C runtime environment should now be setup sufficiently.
 * Set up some pointers, and start decompressing.
 *   r4  = kernel execution address
 *   r7  = architecture ID
 *   r8  = atags pointer
 */
		mov	r0, r4
		mov	r1, sp			@ malloc space above stack
		add	r2, sp, #0x10000	@ 64k max
		mov	r3, r7
		bl	decompress_kernel
		bl	cache_clean_flush
		bl	cache_off
...
```

path: arch/arm/boot/compressed/misc.c
```
void
decompress_kernel(unsigned long output_start, unsigned long free_mem_ptr_p,
		unsigned long free_mem_ptr_end_p,
		int arch_id)
{
	int ret;

	output_data		= (unsigned char *)output_start;
	free_mem_ptr		= free_mem_ptr_p;
	free_mem_end_ptr	= free_mem_ptr_end_p;
	__machine_arch_type	= arch_id;

	arch_decomp_setup();

	putstr("Uncompressing Linux...");
	ret = do_decompress(input_data, input_data_end - input_data,
			    output_data, error);
	if (ret)
		error("decompressor returned an error");
	else
		putstr(" done, booting the kernel.\n");
}
```

* output_start：指解压后内核输出的起始位置，此时它的值参考上面的图表，紧接在解压缓冲区后；
* free_mem_ptr_p：解压函数需要的内存缓冲开始地址；
* free_mem_ptr_end_p：解压函数需要的内存缓冲结束地址，共64K；
* arch_id ：architecture ID.

当完成所有解压任务之后，又将跳转会head.S文件中，执行call_kernel，将启动真正的Image
此时r4寄存器中的地址是0x80208000.也就是内核代码真正的执行地址.

path: arch/arm/boot/compressed/head.S
```
		bl	cache_off
		mov	r0, #0			@ must be zero
		mov	r1, r7			@ restore architecture number
		mov	r2, r8			@ restore atags pointer
 ARM(		mov	pc, r4	)		@ call kernel
 THUMB(		bx	r4	)		@ entry point is always ARM
```

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/kernel/head.S/README.md
