zImage
========================================

zImage的生成过程可以由下图概括:

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/kbuild/res/zImage.gif

zImage
----------------------------------------

生成zImage文件的Makefile位于arch/arm下，它通过
include $(srctree)/arch/$(SRCARCH)/Makefile
被包含进主目录下的Makefie中。另外通过
include $(srctree)/scripts/Kbuild.include
一系列的通用编译器处理函数和变量被包含到主目录下的Makefile中。

根目录下的Makefile:

path: Makefile
```
...
# We need some generic definitions (do not try to remake the file).
$(srctree)/scripts/Kbuild.include: ;
include $(srctree)/scripts/Kbuild.include
...
include $(srctree)/arch/$(SRCARCH)/Makefile
...
```

用于生成zImage的Makefile中的依赖定义如下:

path: arch/arm/Makefile
```
...
# Default target when executing plain make
ifeq ($(CONFIG_XIP_KERNEL),y)
KBUILD_IMAGE := xipImage
else
KBUILD_IMAGE := zImage
endif
...
all:  $(KBUILD_IMAGE) $(KBUILD_DTBS)

boot := arch/arm/boot
...
BOOT_TARGETS = zImage Image xipImage bootpImage uImage
...
$(BOOT_TARGETS): vmlinux
	$(Q)$(MAKE) $(build)=$(boot) MACHINE=$(MACHINE) $(boot)/$@
...
```

由此可以看出zImage依赖于vmlinux文件。当然其他格式的Image文件也
无独有偶的源于vmlinux. 其编译过程如下所示:

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/kbuild/vmlinux.md

### Q变量

其中Q变量位于主目录下, Makefile对Q变量进行了定义:

path: Makefile
```
...
ifeq ("$(origin V)", "command line")
  KBUILD_VERBOSE = $(V)
endif
ifndef KBUILD_VERBOSE
  KBUILD_VERBOSE = 0
endif

ifeq ($(KBUILD_VERBOSE),1)
  quiet =
  Q =
else
  quiet=quiet_
  Q = @
endif
...
```

Q的命运由KBUILD_VERBOSE的值来决定，而螳螂捕蝉，黄雀在后。V最终决定了
Q的命运，通过在make命令参数中提供V=1可以开启V，V是Verbose的缩写，打开
了V，所有的编译信息都将打印出来，关闭V，将获得Beautify output。V选项
对于分析内核的编译很有帮助。

### boot变量

boot := arch/arm/boot 直接指明该架构的boot文件生成路径.

path: arch/arm/Makefile
```
...
boot := arch/arm/boot
...
```

### MACHEINE变量

MACHINE是由用户配置来决定，毕竟一个ARM CPU可以和各类外设组成不同的
机器架构。

path: arch/arm/Makefile
```
# The first directory contains additional information for the boot setup code
ifneq ($(machine-y),)
MACHINE  := arch/arm/mach-$(word 1,$(machine-y))/
else
MACHINE  :=
endif
ifeq ($(CONFIG_ARCH_MULTIPLATFORM),y)
MACHINE  :=
endif
```

### build变量

$(build)=$(boot)被扩展为了scripts/Makefile.build obj=arch/arm/boot，
这看起来有点不太专业。build是scripts/Kbuild.include中定义的变量：

path: scripts/Kbuild.include
```
...
###
# Shorthand for $(Q)$(MAKE) -f scripts/Makefile.build obj=
# Usage:
# $(Q)$(MAKE) $(build)=dir
build := -f $(srctree)/scripts/Makefile.build obj
...
```

### 生成zImage的命令行

一个完整的生成zImage的命令行如下:

```
make -f ./scripts/Makefile.build obj=arch/arm/boot MACHINE= arch/arm/boot/zImage
```

-f指定了实际使用的Makefile文件，obj和MACHINE则是传递给Makefile.build
的参数，它们分别由变量$(boot)和$(MACHINE)决定。$@指参数zImage，
它在Makefile语法中指代生成的目标。

path: scripts/Makefile.build
```
...
src := $(obj)
...
# The filename Kbuild has precedence over Makefile
kbuild-dir := $(if $(filter /%,$(src)),$(src),$(srctree)/$(src))
kbuild-file := $(if $(wildcard $(kbuild-dir)/Kbuild),$(kbuild-dir)/Kbuild,$(kbuild-dir)/Makefile)
include $(kbuild-file)
...
```

kbuild-file既是src指定路径下的Makefile文件，此时就是
arch/arm/boot/Makefile，它包含了构建arch/arm/boot/zImage的规则。

### 生成规则

path: arch/arm/boot/Makefile
```
...
$(obj)/zImage:	$(obj)/compressed/vmlinux FORCE
	$(call if_changed,objcopy)
	@$(kecho) '  Kernel: $@ is ready'
...
```

将$(obj)/compressed/vmlinux经过objcopy处理后便生成了最终的zImage

### 扩展命令

```
arm-none-eabi-objcopy -O binary -R .comment -S  arch/arm/boot/compressed/vmlinux arch/arm/boot/zImage
```

变量obj的值即是arch/arm/boot. zImage此时又依赖于$(obj)/compressed/vmlinux.

arch/arm/boot/compressed/vmlinux
----------------------------------------

### 初步生成规则

path: arch/arm/boot/Makefile
```
...
$(obj)/compressed/vmlinux: $(obj)/Image FORCE
	$(Q)$(MAKE) $(build)=$(obj)/compressed $@
...
```

生成依赖的arch/arm/boot/Image

### arch/arm/boot/Image

#### 生成规则

path: arch/arm/boot/Makefile
```
$(obj)/Image: vmlinux FORCE
	$(call if_changed,objcopy)
	@$(kecho) '  Kernel: $@ is ready'
```

变量obj的值即是arch/arm/boot. arch/arm/boot/Image此时依赖根目录下生成的vmlinux文件.
接下来调用objcopy生成Image文件:

path: scripts/Makefile.lib
```
...
quiet_cmd_objcopy = OBJCOPY $@
cmd_objcopy = $(OBJCOPY) $(OBJCOPYFLAGS) $(OBJCOPYFLAGS_$(@F)) $< $@
...
```

#### 扩展命令

```
arm-none-eabi-objcopy -O binary -R .comment -S  vmlinux arch/arm/boot/Image
```

### 生成vmlinux的命令行

```
make -f scripts/Makefile.build obj=arch/arm/boot/compressed arch/arm/boot/compressed/vmlinux
```

变量obj的值即是arch/arm/boot/compressed. scripts/Makefile.build会自动包含
arch/arm/boot/compressed/Makefile，该文件指明了arch/arm/boot/compressed/vmlinux的生成规则:

### 最终生成规则

path: arch/arm/boot/compressed/Makefile
```
...
HEAD	= head.o
...
$(obj)/vmlinux: $(obj)/vmlinux.lds $(obj)/$(HEAD) $(obj)/piggy.$(suffix_y).o \
		$(addprefix $(obj)/, $(OBJS)) $(lib1funcs) $(ashldi3) \
		$(bswapsdi2) FORCE
	@$(check_for_multiple_zreladdr)
	$(call if_changed,ld)
	@$(check_for_bad_syms)
...
```

在这里obj变量为arch/arm/boot/compressed.接下来调用if_changed扩展的ld命令，根据链接脚本
arch/arm/boot/compressed/vmlinux.lds链接生成了arch/arm/boot/compressed/vmlinux文件.

path: scripts/Makefile.lib
```
quiet_cmd_ld = LD      $@
cmd_ld = $(LD) $(LDFLAGS) $(ldflags-y) $(LDFLAGS_$(@F)) \
	       $(filter-out FORCE,$^) -o $@
```

### 扩展命令

```
arm-none-eabi-ld -EL    --defsym _kernel_bss_size=152056 -p --no-undefined -X -T arch/arm/boot/compressed/vmlinux.lds arch/arm/boot/compressed/head.o arch/arm/boot/compressed/piggy.gzip.o arch/arm/boot/compressed/misc.o arch/arm/boot/compressed/decompress.o arch/arm/boot/compressed/string.o arch/arm/boot/compressed/hyp-stub.o arch/arm/boot/compressed/lib1funcs.o arch/arm/boot/compressed/ashldi3.o arch/arm/boot/compressed/bswapsdi2.o -o arch/arm/boot/compressed/vmlinux
```

### vmlinux.lds

arch/arm/kernel/compressed/vmlinux.lds是由arch/arm/kernel/compressed/vmlinux.lds.S生成的,

#### 生成规则

path: scripts/Makefile.build
```
# Linker scripts preprocessor (.lds.S -> .lds)
# ---------------------------------------------------------------------------
quiet_cmd_cpp_lds_S = LDS     $@
      cmd_cpp_lds_S = $(CPP) $(cpp_flags) -P -C -U$(ARCH) \
	                     -D__ASSEMBLY__ -DLINKER_SCRIPT -o $@ $<

$(obj)/%.lds: $(src)/%.lds.S FORCE
	$(call if_changed_dep,cpp_lds_S)
```

#### 扩展命令

```
  arm-none-eabi-gcc -E -Wp,-MD,arch/arm/boot/compressed/.vmlinux.lds.d  -nostdinc -isystem /home/liminghao/bin/bin/arm-none-eabi-4.7.3/bin/../lib/gcc/arm-none-eabi/4.7.3/include -I./arch/arm/include -Iarch/arm/include/generated/uapi -Iarch/arm/include/generated  -Iinclude -I./arch/arm/include/uapi -Iarch/arm/include/generated/uapi -I./include/uapi -Iinclude/generated/uapi -include ./include/linux/kconfig.h -D__KERNEL__ -mlittle-endian     -DTEXT_START="0" -DBSS_START="ALIGN(8)" -P -C -Uarm -D__ASSEMBLY__ -DLINKER_SCRIPT -o arch/arm/boot/compressed/vmlinux.lds arch/arm/boot/compressed/vmlinux.lds.S
```

生成命令中的参数-E，它并不编译，而只是进行预处理。它的格式与源文件格式是一致的。

#### vmlinux.lds.S

```
# ENTRY连接脚本命令来设置入口点.参数是一个符号名,在这里是符号名_start;
ENTRY(_start)
...
SECTIONS
{
  ...
  # "."赋值, 这是一个定位计数器. 如果没有以其它的方式指定输出节的地址,
  # 那地址值就会被设为定位计数器的现有值TEXT_START.
  . = TEXT_START;
  _text = .;

  # 定义一个输出节.text, 冒号是语法需要,现在可以被忽略. 节名后面的花括号中,
  # 你列出所有应当被放入到这个输出节中的输入节的名字. '*'是一个通配符,匹配任何文件名.
  # 当输出节.text定义的时候, 定位计数器的值是TEXT_START,连接器会把输出文件中的.text节的
  # 地址设为TEXT_START
  .text : {
    _start = .;
    # 总是将.head中的.start段安排在0地址处
    *(.start)
    # *(.text)意思是所有的输入文件中的".text"输入节.
    *(.text)
    *(.text.*)
    *(.fixup)
    *(.gnu.warning)
    *(.glue_7t)
    *(.glue_7)
  }
  .rodata : {
    *(.rodata)
    *(.rodata.*)
  }
  .piggydata : {
    *(.piggydata)
  }

  . = ALIGN(4);
  _etext = .;

  .got.plt		: { *(.got.plt) }
  _got_start = .;
  .got			: { *(.got) }
  _got_end = .;

  /* ensure the zImage file size is always a multiple of 64 bits */
  /* (without a dummy byte, ld just ignores the empty section) */
  .pad			: { BYTE(0); . = ALIGN(8); }
  # _edata实际上就是zImage文件的大小。它包含内核镜像所需的所有代码段和数据段以及压缩后
  # 的vmlinux内核文件.piggydata数据段。
  _edata = .;

  _magic_sig = ZIMAGE_MAGIC(0x016f2818);
  _magic_start = ZIMAGE_MAGIC(_start);
  _magic_end = ZIMAGE_MAGIC(_edata);

  . = BSS_START;
  __bss_start = .;
  .bss			: { *(.bss) }
  _end = .;

  . = ALIGN(8);		/* the stack must be 64-bit aligned */
  .stack		: { *(.stack) }

  .stab 0		: { *(.stab) }
  .stabstr 0		: { *(.stabstr) }
  .stab.excl 0		: { *(.stab.excl) }
  .stab.exclstr 0	: { *(.stab.exclstr) }
  .stab.index 0		: { *(.stab.index) }
  .stab.indexstr 0	: { *(.stab.indexstr) }
  .comment 0		: { *(.comment) }
}
```

TEXT_START的定义如下如下所示, 在这里该值为0x0:

path: arch/arm/boot/compressed/Makefile
```
...
#
# We now have a PIC decompressor implementation.  Decompressors running
# from RAM should not define ZTEXTADDR.  Decompressors running directly
# from ROM or Flash must define ZTEXTADDR (preferably via the config)
# FIXME: Previous assignment to ztextaddr-y is lost here. See SHARK
ifeq ($(CONFIG_ZBOOT_ROM),y)
ZTEXTADDR	:= $(CONFIG_ZBOOT_ROM_TEXT)
ZBSSADDR	:= $(CONFIG_ZBOOT_ROM_BSS)
else
ZTEXTADDR	:= 0
ZBSSADDR	:= ALIGN(8)
endif

CPPFLAGS_vmlinux.lds := -DTEXT_START="$(ZTEXTADDR)" -DBSS_START="$(ZBSSADDR)"
...
```

vmlinux依赖于$(obj)/piggy.$(suffix_y).o, 其生成规则如下所示:

arch/arm/boot/compressed/piggy.$(suffix_y).o
----------------------------------------

### 生成规则

path: arch/arm/boot/compressed/Makefile
```
suffix_$(CONFIG_KERNEL_GZIP) = gzip
...
$(obj)/piggy.$(suffix_y): $(obj)/../Image FORCE
	$(call if_changed,$(suffix_y))

$(obj)/piggy.$(suffix_y).o:  $(obj)/piggy.$(suffix_y) FORCE
```

这两个规则就是将生成的Image进行压缩成piggy.gzip. 然后生成piggy.gzip.o

### 扩展命令

```
  (cat arch/arm/boot/compressed/../Image | gzip -n -f -9 > arch/arm/boot/compressed/piggy.gzip) || (rm -f arch/arm/boot/compressed/piggy.gzip ; false)

  arm-none-eabi-gcc -Wp,-MD,arch/arm/boot/compressed/.piggy.gzip.o.d  -nostdinc -isystem /home/liminghao/bin/bin/arm-none-eabi-4.7.3/bin/../lib/gcc/arm-none-eabi/4.7.3/include -I./arch/arm/include -Iarch/arm/include/generated/uapi -Iarch/arm/include/generated  -Iinclude -I./arch/arm/include/uapi -Iarch/arm/include/generated/uapi -I./include/uapi -Iinclude/generated/uapi -include ./include/linux/kconfig.h -D__KERNEL__ -mlittle-endian   -D__ASSEMBLY__ -mabi=aapcs-linux -mno-thumb-interwork -mfpu=vfp -funwind-tables -marm -D__LINUX_ARM_ARCH__=7 -march=armv7-a  -include asm/unified.h -msoft-float -Wa,-gdwarf-2 -DCC_HAVE_ASM_GOTO        -DZIMAGE     -c -o arch/arm/boot/compressed/piggy.gzip.o arch/arm/boot/compressed/piggy.gzip.S
```

不知是Russell King还是Linus Torvalds更喜欢小猪，反正piggy被引入到了ARM的引导代码中。据考piggy是
从piggyback缩写而来的，中文意为“骑在肩上”，显然是指Linux的启动需要“骑在”piggy.gz的肩上了。

* -f或--force: 强行压缩文件。不理会文件名称或硬连接是否存在以及该文件是否为符号连接。
* -1或--fast: 表示最快压缩方法（低压缩比）.
* -9或--best表示最慢压缩方法（高压缩比）。

使用最高压缩比将arch/arm/boot/compressed/../Image压缩为arch/arm/boot/compressed/piggy.gzip，
小猪诞生了。

命令行中没有提到任何piggy.gzip的信息，但是生成的.o文件的大小几乎和.gzip文件一致，
而piggy.gzip.S则很小，问题出在哪呢？piggy.gzip.S的内容表明了一切：

path: arch/arm/boot/compressed/piggy.gzip.S
```
	.section .piggydata,#alloc
	.globl	input_data
input_data:
	.incbin	"arch/arm/boot/compressed/piggy.gzip"
	.globl	input_data_end
input_data_end:
```

定义了一个名为.piggydata的段，该段中的数据就是piggy.gzip。input_data符号要被链接器用到，
所以要标记它是一个.globl全局符号。.incbin指令在被汇编的文件内包含一个文件，该文件按原样
包含，没有进行汇编。input_data_end符号也要被外部引用。input_data被外部引用时的值为piggy.gzip
文件在piggy.gzip.o的起始地址，input_data_end则是结束地址。这里给出证明:

```
$ arm-none-eabi-readelf -S binary/arch/arm/boot/compressed/piggy.gzip.o
There are 9 section headers, starting at offset 0x345a34:

Section Headers:
  [Nr] Name              Type            Addr     Off    Size   ES Flg Lk Inf Al
  [ 0]                   NULL            00000000 000000 000000 00      0   0  0
  [ 1] .text             PROGBITS        00000000 000034 000000 00  AX  0   0  1
  [ 2] .data             PROGBITS        00000000 000034 000000 00  WA  0   0  1
  [ 3] .bss              NOBITS          00000000 000034 000000 00  WA  0   0  1
  [ 4] .piggydata        PROGBITS        00000000 000034 345998 00   A  0   0  1
  [ 5] .ARM.attributes   ARM_ATTRIBUTES  00000000 3459cc 00001f 00      0   0  1
  [ 6] .shstrtab         STRTAB          00000000 3459eb 000047 00      0   0  1
  [ 7] .symtab           SYMTAB          00000000 345b9c 000080 10      8   6  4
  [ 8] .strtab           STRTAB          00000000 345c1c 00001b 00      0   0  1
Key to Flags:
  W (write), A (alloc), X (execute), M (merge), S (strings)
  I (info), L (link order), G (group), T (TLS), E (exclude), x (unknown)
  O (extra OS processing required) o (OS specific), p (processor specific)
$ ll binary/arch/arm/boot/compressed/piggy.gzip
-rw-rw-r-- 1 liminghao liminghao 3430808 Aug 23 22:21 binary/arch/arm/boot/compressed/piggy.gzip
```

注意到piggydata中的SIZE为0x345998，转换为十进制就是3430808。并且
input_data的值为0x34，input_data_end的值为0x3459cc
