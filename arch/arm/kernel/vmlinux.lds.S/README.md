Kernel linker script
========================================

Linker script中的语法是linker command language, 那么LS的目的是什么呢？
LS描述输入文件（也就是gcc -c命令产生的.o文件即object文件）中的section最终如何对应到一个输出文件。
例如一个elf由三个.o文件构成，每个.o文件都有text/data/bss段，但最终的那一个elf就会将三个输入的.o
文件的段合并到一起。

example
----------------------------------------

```
SECTIONS
 {
       . = 0x10000;
       .text : { *(.text) }
       . = 0x8000000;
       .data : { *(.data) }
       .bss : { *(.bss) }
 }
```

* SECTIONS是LS语法中的关键command，它用来描述输出文件的内存布局。例如上例中就含text/data/bss
  三个部分（实际上text/data/bss才是段，但是SECTIONS这个词在LS中是一个command）。

* .=0x10000; 其中的.非常关键，它代表location counter（LC）。意思是.text段的开始设置在0x10000处。
  这个LC应该指的是LMA，但大多数情况下VMA=LMA。

* .text:{*(.text)}，这个表示输出文件的.text段内容由所有输入文件(*)的.text段组成。组成顺序就是
  ld命令中输入文件的顺序，例如1.obj,2.obj......

* .=0x800000000;。如果没有这个赋值的，那么LC应该等于0x10000+sizeof(text段)，即LC如果不强制指定的
  话，它默认就是上一次的LC+中间section的长度。还好，这里强制指定LC=0X800000000.表明后面的
  .data段的开始位于这个地址。

* .data和后面的.bss表示分别有输入文件的.data和.bss段构成。

vmlinux.lds.S
----------------------------------------

```
/* OUTPUT_ARCH是LS语法中的COMMAND，用来指定输出文件的machine arch */
OUTPUT_ARCH(arm)
/* ENTRY也是一个command，用来设置入口点。这里表示入口点是stext 。根据LD的描述，入口点的意思
 * 就是程序运行的第一条指令
 */
ENTRY(stext)

#ifndef __ARMEB__
jiffies = jiffies_64;
#else
jiffies = jiffies_64 + 4;
#endif

/*
 * LS语法中，关于seciton的定义如下：
 * section [address] [(type)] :
 *      [AT(lma)] [ALIGN(section_align)]
 *      [SUBALIGN(subsection_align)]
 *      [constraint]
 *      {
 *        output-section-command
 *        output-section-command
 *        ...
 *      } [>region] [AT>lma_region] [:phdr :phdr ...] [=fillexp]
 * 其中，address为VMA，而AT命令中的为LMA。一般情况，address不会设置，所以它默认等于当前的
 * location counter
 */
SECTIONS
{
	/*
	 * XXX: The linker does not define how output sections are
	 * assigned to input sections when there are multiple statements
	 * matching the same input section name.  There is no documented
	 * order of matching.
	 *
	 * unwind exit sections must be discarded before the rest of the
	 * unwind sections get included.
	 */
         /* DISACARD是一个特殊的section，表示符合这个条件的输入段都不会写到输出段中，
          * 也就是输出文件中不包含下列段 */
	/DISCARD/ : {
		*(.ARM.exidx.exit.text)
		*(.ARM.extab.exit.text)
		ARM_CPU_DISCARD(*(.ARM.exidx.cpuexit.text))
		ARM_CPU_DISCARD(*(.ARM.extab.cpuexit.text))
		ARM_EXIT_DISCARD(EXIT_TEXT)
		ARM_EXIT_DISCARD(EXIT_DATA)
		EXIT_CALL
#ifndef CONFIG_HOTPLUG
		*(.ARM.exidx.devexit.text)
		*(.ARM.extab.devexit.text)
#endif
#ifndef CONFIG_MMU
		*(.fixup)
		*(__ex_table)
#endif
#ifndef CONFIG_SMP_ON_UP
		*(.alt.smp.init)
#endif
		*(.discard)
		*(.discard.*)
	}

#ifdef CONFIG_XIP_KERNEL
	. = XIP_VIRT_ADDR(CONFIG_XIP_PHYS_ADDR);
#else
        /* 设置Location count为0xc0008000. 内核运行的地址全在C0000000以上 */
	. = PAGE_OFFSET + TEXT_OFFSET;
#endif
        /* 定义一个.text.head段，由输入文件中所有.text.head段组成 */
	.head.text : {
		_text = .;
		HEAD_TEXT
	}
```

在内核代码中经常能看到一些变量声明，例如extern int __stext，但是却找不到在哪定义的
其实这些都是在lds文件中定义的。这里得说一下编译链接相关的小知识。

假设C代码中定义一个变量int x = 0;那么

* 1.编译器首先会分配一块内存，用来存储该变量的值.
* 2.编译器在程序的symbol表中，创建一项，用来存储这个变量的地址.

例如，上面的 int x = 0,就在symbol表中创建一x项，这个x项指向一块内存，sizeof(int)大小，存储的值为0。
当有地方使用这个x的时候，编译器会生成相应的代码，首先指向这个x的内存，然后读取内存中的值。
上面的内容是C中一个变量的定义。

Linker script中也可以定义变量，这时候只会生成一个symbol项，但是没有分配内存。
例如, _stext=0x100,那么会创建一个symbol项，指向0x100的内存，但该内存中没有存储value。
所以，我们在C中使用LS中定义的变量的话，只能取它的地址。下面是一个例子：

```
start_of_ROM   = .ROM;
end_of_ROM     = .ROM + sizeof (.ROM) - 1;
start_of_FLASH = .FLASH;
```

上面三个变量是在LS中定义的，分别指向.ROM段的开始和结尾，以及FLASH段的开始。现在在C代码中想把
ROM段的内容拷贝到FLASH段中，下面是C代码：

```
extern char start_of_ROM, end_of_ROM, start_of_FLASH;
memcpy (& start_of_FLASH, & start_of_ROM, & end_of_ROM - & start_of_ROM);
```

注意其中的取地址符号&。C代码中只能通过这种方式来使用LS中定义的变量.
start_of_ROM这个值本身是没有意义的，只有它的地址才有意义。因为它的值没有初始化.
地址就指向.ROM段的开头。

说白了，LS中定义的变量其实就是地址，即_stext=0x100就是C代码中的一个地址 int *_stext=0x100。明白了？
最终的ld中会分配一个slot，然后存储x的地址。ld知道这些勾当。那么当然我们在LS中也可以定义一个变量，
然后在C中使用了。所以下面这句话实际上定义了一个_stext变量。在C中通过extern就可以引用了。

```
#ifdef CONFIG_STRICT_MEMORY_RWX
	. = ALIGN(1<<SECTION_SHIFT);
#endif

	.text : {			/* Real text segment		*/
        /* 所以下面这句话实际上定义了一个_stext变量。在C中通过extern就可以引用了。 */
		_stext = .;		/* Text and read-only data	*/
			__exception_text_start = .;
			*(.exception.text)
			__exception_text_end = .;
			IRQENTRY_TEXT
			TEXT_TEXT
			SCHED_TEXT
			LOCK_TEXT
			KPROBES_TEXT
			IDMAP_TEXT
#ifdef CONFIG_MMU
			*(.fixup)
#endif
			*(.gnu.warning)
			*(.glue_7)
			*(.glue_7t)
		. = ALIGN(4);
		*(.got)			/* Global offset table		*/
			ARM_CPU_KEEP(PROC_INFO)
	}

#ifdef CONFIG_STRICT_MEMORY_RWX
	. = ALIGN(1<<SECTION_SHIFT);
#endif
	RO_DATA(PAGE_SIZE)

#ifdef CONFIG_ARM_UNWIND
	/*
	 * Stack unwinding tables
	 */
	. = ALIGN(8);
	.ARM.unwind_idx : {
		__start_unwind_idx = .;
		*(.ARM.exidx*)
		__stop_unwind_idx = .;
	}
	.ARM.unwind_tab : {
		__start_unwind_tab = .;
		*(.ARM.extab*)
		__stop_unwind_tab = .;
	}
#endif

	_etext = .;			/* End of text and rodata section */

#ifndef CONFIG_XIP_KERNEL
#ifdef CONFIG_STRICT_MEMORY_RWX
	. = ALIGN(1<<SECTION_SHIFT);
#else
	. = ALIGN(PAGE_SIZE);
#endif
	__init_begin = .;
#endif
	/*
	 * The vectors and stubs are relocatable code, and the
	 * only thing that matters is their relative offsets
	 */
	__vectors_start = .;
	.vectors 0 : AT(__vectors_start) {
		*(.vectors)
	}
	. = __vectors_start + SIZEOF(.vectors);
	__vectors_end = .;

	__stubs_start = .;
	.stubs 0x1000 : AT(__stubs_start) {
		*(.stubs)
	}
	. = __stubs_start + SIZEOF(.stubs);
	__stubs_end = .;

	INIT_TEXT_SECTION(8)
	.exit.text : {
		ARM_EXIT_KEEP(EXIT_TEXT)
	}
	.init.proc.info : {
		ARM_CPU_DISCARD(PROC_INFO)
	}
#ifdef CONFIG_STRICT_MEMORY_RWX
	. = ALIGN(1<<SECTION_SHIFT);
#endif
```

如下大部分都是一个begin+end来卡住一段内容。根据前面的介绍,begin和end又可以在C程序中引用
也就是我们通过Begin+end，就可以获得卡住的内容了。例如我们把一些初始化的函数指针放到一个
begin和end中。然后通过一个循环，不就是可以调用这些函数了么.

```
	.init.arch.info : {
		__arch_info_begin = .;
		*(.arch.info.init)
		__arch_info_end = .;
	}
	.init.tagtable : {
		__tagtable_begin = .;
		*(.taglist.init)
		__tagtable_end = .;
	}
#ifdef CONFIG_SMP_ON_UP
	.init.smpalt : {
		__smpalt_begin = .;
		*(.alt.smp.init)
		__smpalt_end = .;
	}
#endif
	.init.pv_table : {
		__pv_table_begin = .;
		*(.pv_table)
		__pv_table_end = .;
	}

        ...
	NOTES

	BSS_SECTION(0, 0, 0)
	_end = .;

	STABS_DEBUG
	.comment 0 : { *(.comment) }
}

/*
 * These must never be empty
 * If you have to comment these two assert statements out, your
 * binutils is too old (for other reasons as well)
 */
ASSERT((__proc_info_end - __proc_info_begin), "missing CPU support")
ASSERT((__arch_info_end - __arch_info_begin), "no machine record defined")
```

LMA 和 VMA
----------------------------------------

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/arch/arm/kernel/VMA_LMA.md
