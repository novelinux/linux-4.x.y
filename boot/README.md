Linux内核启动
========================================

当bootloader完成它的使命之后就将CPU的使用权交给了Linux内核.Linux内核通常是以zImage的形式被
bootloader加载并执行的。

https://github.com/novelinux/bootloader-lk/tree/master/README.md

zImage编译过程
----------------------------------------

我们先来研究下zImage的生成过程及其组成部分，如下所示:

https://github.com/novelinux/linux-4.x.y/tree/master/kbuild/zImage.md

zImage的执行
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

https://github.com/novelinux/bootloader-lk/tree/master/lk/README.md

对应的内存布局如下：

https://github.com/novelinux/arch-arm-msm-8960/tree/master/memory_layout.md

在bootloader将kernel信息加载到内存，然后变跳转到内核执行. 根据分析zImage的编译过程
我们得知，内核第一条指令的地址是arch/arm/boot/compressed/head.S第一条指令的地址.

### ARM

反汇编kbuild/binary/arch/arm/boot/compressed/vmlinux，查看0x0地址开始处的代码:

反汇编命令: $ arm-eabi-objdump -S vmlinux > vmlinux.S
**注意**: 不能直接反汇编zImage,因为zImage是使用objcopy将vmlinux(elf格式)生成原始二进制文件zImage.
反汇编后代码如下所示:

path: kbuild/binary/arch/arm/boot/compressed/vmlinux.S
```
...
00000000 <start>:
       0:	e1a00000 	nop			; (mov r0, r0)
       4:	e1a00000 	nop			; (mov r0, r0)
       8:	e1a00000 	nop			; (mov r0, r0)
       c:	e1a00000 	nop			; (mov r0, r0)
      10:	e1a00000 	nop			; (mov r0, r0)
      14:	e1a00000 	nop			; (mov r0, r0)
      18:	e1a00000 	nop			; (mov r0, r0)
      1c:	e1a00000 	nop			; (mov r0, r0)
      20:	ea000003 	b	34 <start+0x34>
      # 查看对应vmlinux.lds.S和head.S得知
      # 第一个字数据是zImage的魔数;
      # 第二个对应start地址;
      # 第三个为_edata的值为0x0034a288.即对应zImage的大小.
      # 第四个为字节顺序标志.
      24:	016f2818 	.word	0x016f2818
      28:	00000000 	.word	0x00000000
      2c:	0034a288 	.word	0x0034a288
      30:	04030201 	.word	0x04030201
      34:	e10f9000 	mrs	r9, CPSR
      38:	eb000e00 	bl	3840 <__hyp_stub_install>
      3c:	e1a07001 	mov	r7, r1
      40:	e1a08002 	mov	r8, r2
      44:	e10f2000 	mrs	r2, CPSR
      48:	e3120003 	tst	r2, #3
      4c:	1a000001 	bne	58 <not_angel>
      50:	e3a00017 	mov	r0, #23
      54:	ef123456 	svc	0x00123456
...
```

https://github.com/novelinux/linux-4.x.y/tree/master/kbuild/binary/arch/arm/boot/compressed/vmlinux_aries.S

Code Flow
----------------------------------------

```
bootloader
    |
  zImage
    |
  head.o
```

上述反汇编出来的0地址处部分代码,即为对应head.S文件start标志处开始的代码，如下所示:

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/boot/compressed/head.S/README.md
