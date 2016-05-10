vmlinux
========================================

vmlinux是主目录Makefile的最终目标，其他镜像文件的依赖。
其编译过程如下所示:

vmlinux
----------------------------------------

vmlinux目标的生成规则在顶层Makefile中定义如下所示:

### 生成规则

path: Makefile
```
# The all: target is the default when no target is given on the
# command line.
# This allow a user to issue only 'make' to build a kernel including modules
# Defaults to vmlinux, but the arch makefile usually adds further targets
all: vmlinux
...
# Include targets which we want to
# execute if the rest of the kernel build went well.
vmlinux: scripts/link-vmlinux.sh $(vmlinux-deps) FORCE
ifdef CONFIG_HEADERS_CHECK
	$(Q)$(MAKE) -f $(srctree)/Makefile headers_check
endif
ifdef CONFIG_SAMPLES
	$(Q)$(MAKE) $(build)=samples
endif
ifdef CONFIG_BUILD_DOCSRC
	$(Q)$(MAKE) $(build)=Documentation
endif
	+$(call if_changed,link-vmlinux)
```

如果使能CONFIG_HEADERS_CHECK将尝试对所有导出的.h进行有效性检查。
接下来通过if_changed命令扩展调用cmd_link-vmlinux或
quiet_cmd_link-vmlinux来生成vmlinux:

path: Makefile
```
# Final link of vmlinux
      cmd_link-vmlinux = $(CONFIG_SHELL) $< $(LD) $(LDFLAGS) $(LDFLAGS_vmlinux)
quiet_cmd_link-vmlinux = LINK    $@
```

### 扩展命令

```
arm-none-eabi-ld -EL -p --no-undefined -X --pic-veneer --build-id -o vmlinux -T ./arch/arm/kernel/vmlinux.lds arch/arm/kernel/head.o init/built-in.o --start-group usr/built-in.o arch/arm/vfp/built-in.o arch/arm/vdso/built-in.o arch/arm/kernel/built-in.o arch/arm/mm/built-in.o arch/arm/common/built-in.o arch/arm/probes/built-in.o arch/arm/net/built-in.o arch/arm/crypto/built-in.o arch/arm/firmware/built-in.o arch/arm/mach-vexpress/built-in.o arch/arm/plat-versatile/built-in.o kernel/built-in.o mm/built-in.o fs/built-in.o ipc/built-in.o security/built-in.o crypto/built-in.o block/built-in.o arch/arm/lib/lib.a lib/lib.a arch/arm/lib/built-in.o lib/built-in.o drivers/built-in.o sound/built-in.o firmware/built-in.o arch/arm/oprofile/built-in.o net/built-in.o --end-group .tmp_kallsyms2.o
```

注意到--start-group和--end-group参数，它们是为了解决静态库之间相互引用，
所有的静态库应该放到它们之间。

if_changed命令定义如下所示:

https://github.com/novelinux/linux-4.x.y/tree/master/kbuild/cmd.md

### vmlinux.lds

arch/arm/kernel/vmlinux.lds 是由arch/arm/kernel/vmlinux.lds.S生成的.生成规则如下所示:

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
  arm-none-eabi-gcc -E -Wp,-MD,arch/arm/kernel/.vmlinux.lds.d  -nostdinc -isystem /home/liminghao/bin/bin/arm-none-eabi-4.7.3/bin/../lib/gcc/arm-none-eabi/4.7.3/include -I./arch/arm/include -Iarch/arm/include/generated/uapi -Iarch/arm/include/generated  -Iinclude -I./arch/arm/include/uapi -Iarch/arm/include/generated/uapi -I./include/uapi -Iinclude/generated/uapi -include ./include/linux/kconfig.h -D__KERNEL__ -mlittle-endian     -DTEXT_OFFSET=0x00008000 -P -C -Uarm -D__ASSEMBLY__ -DLINKER_SCRIPT -o arch/arm/kernel/vmlinux.lds arch/arm/kernel/vmlinux.lds.S
```

注意到生成命令中的参数-E，它并不编译，而只是进行预处理。它的格式与源文件格式是一致的。

vmlinux.lds.S定义了代码段的开始位置:

path: arch/arm/kernel/vmlinux.lds.S
```
SECTIONS
{
...
#ifdef CONFIG_XIP_KERNEL
	. = XIP_VIRT_ADDR(CONFIG_XIP_PHYS_ADDR);
#else
	. = PAGE_OFFSET + TEXT_OFFSET;
#endif
...
}
```

* TEXT_OFFSET

-DTEXT_OFFSET=0x00008000指定了脚本生成时TEXT_OFFSET参数.

path: arch/arm/Makefile
```
# Text offset. This list is sorted numerically by address in order to
# provide a means to avoid/resolve conflicts in multi-arch kernels.
textofs-y	:= 0x00008000
...
# The byte offset of the kernel image in RAM from the start of RAM.
TEXT_OFFSET := $(textofs-y)
...
```

* PAGE_OFFSET

头文件memory.h对PAGE_OFFSET做了如下定义

path: arch/arm/include/asm/memory.h
```
/* PAGE_OFFSET - the virtual address of the start of the kernel image */
#define PAGE_OFFSET		UL(CONFIG_PAGE_OFFSET)
```

最终内核的代码段的开始地址如下:

```
. = 0xC0000000 + 0x00008000;
```

vmlinux的生成最初依赖于scripts/link-vmlinux.sh脚本和变量vmlinux-deps中定义的文件.
vmlinux-deps的生成规则如下所示:

vmlinux-deps
----------------------------------------

### 生成规则

path: Makefile
```
...
# Externally visible symbols (used by link-vmlinux.sh)
export KBUILD_VMLINUX_INIT := $(head-y) $(init-y)
export KBUILD_VMLINUX_MAIN := $(core-y) $(libs-y) $(drivers-y) $(net-y)
export KBUILD_LDS          := arch/$(SRCARCH)/kernel/vmlinux.lds
...
vmlinux-deps := $(KBUILD_LDS) $(KBUILD_VMLINUX_INIT) $(KBUILD_VMLINUX_MAIN)
...
# The actual objects are generated when descending,
# make sure no implicit rule kicks in
$(sort $(vmlinux-deps)): $(vmlinux-dirs) ;
```

找到各个子目录中的.o目标文件并赋值给vmlinux-deps变量之后，vmlinux-deps的构建规则如上所示,
这里是一个空命令的规则, 空命令行可以防止make在执行时试图为重建这个目标去查找隐含命令。

#### head-y

path: arch/arm/Makefile
```
...
#Default value
head-y		:= arch/arm/kernel/head$(MMUEXT).o
...
```

#### init-y

path: Makefile
```
...
# Objects we will link into vmlinux / subdirs we need to visit
init-y		:= init/
...
init-y		:= $(patsubst %/, %/built-in.o, $(init-y))
...
```

上述语句的目的就是找到init目录中所有被编译成built-in.o的目标文件，其余
core-y, libs-y, drivers-y, net-y变量的解析类似.

#### core-y

path: Makefile
```
...
core-y		:= usr/
...
core-y		+= kernel/ mm/ fs/ ipc/ security/ crypto/ block/
...
core-y		:= $(patsubst %/, %/built-in.o, $(core-y))
...
```

#### libs-y

path: Makefile
```
...
libs-y		:= lib/
...
libs-y1		:= $(patsubst %/, %/lib.a, $(libs-y))
libs-y2		:= $(patsubst %/, %/built-in.o, $(libs-y))
libs-y		:= $(libs-y1) $(libs-y2)
...
```

#### drivers-y

path: Makefile
```
...
drivers-y	:= drivers/ sound/ firmware/
...
drivers-y	:= $(patsubst %/, %/built-in.o, $(drivers-y))
...
```

#### net-y

path: Makefile
```
...
net-y		:= net/
...
net-y		:= $(patsubst %/, %/built-in.o, $(net-y))
...
```

vmlinux-deps依赖于vmlinux-dirs，这个变量生成规则如下所示:

vmlinux-dirs
----------------------------------------

### 生成规则

path: Makefile
```
vmlinux-dirs	:= $(patsubst %/,%,$(filter %/, $(init-y) $(init-m) \
		     $(core-y) $(core-m) $(drivers-y) $(drivers-m) \
		     $(net-y) $(net-m) $(libs-y) $(libs-m)))
```

这个变量指定了一系列要进入的下层目录,其规则定义如下所示:

path: Makefile
```
# Handle descending into subdirectories listed in $(vmlinux-dirs)
# Preset locale variables to speed up the build process. Limit locale
# tweaks to this spot to avoid wrong language settings when running
# make menuconfig etc.
# Error messages still appears in the original language

PHONY += $(vmlinux-dirs)
$(vmlinux-dirs): prepare scripts
	$(Q)$(MAKE) $(build)=$@
```

build是scripts/Kbuild.include中定义的变量：

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

### vmlinux-dir的完整生成命令

```
$(Q)$(MAKE) -f $(srctree)/scripts/Makefile.build obj=$(vmlinux-dirs)
```

以init目录为例，该命令如下所示:

```
make -f ./scripts/Makefile.build obj=init
```

这里会进入scripts/Makefile.build执行规则如下所示:

path: scripts/Makefile.build
```
...
PHONY := __build
__build:
...
__build: $(if $(KBUILD_BUILTIN),$(builtin-target) $(lib-target) $(extra-y)) \
	 $(if $(KBUILD_MODULES),$(obj-m) $(modorder-target)) \
	 $(subdir-ym) $(always)
	@:
...
```

KBUILD_BUILTIN在顶层Makefile中被初始化为1，所以这个规则的依赖需要
builtin-target, lib-target, extra-y变量。其中builtin-target这个
变量定义如下所示:

path: scripts/Makefile.build
```
...
ifneq ($(strip $(obj-y) $(obj-m) $(obj-) $(subdir-m) $(lib-target)),)
builtin-target := $(obj)/built-in.o
endif
...
```

变量obj就是vmlinux-dirs变量指定的目录,在我们的例子中是init。所以这里
会构建$(vmlinux-dirs)/built-in.o目标，这个目标的规则及命令的定义如下:

builtin-target
----------------------------------------

### 生成规则

path: scripts/Makefile.build
```
#
# Rule to compile a set of .o files into one .o file
#
ifdef builtin-target
quiet_cmd_link_o_target = LD      $@
# If the list of objects to link is empty, just create an empty built-in.o
cmd_link_o_target = $(if $(strip $(obj-y)),\
		      $(LD) $(ld_flags) -r -o $@ $(filter $(obj-y), $^) \
		      $(cmd_secanalysis),\
		      rm -f $@; $(AR) rcs$(KBUILD_ARFLAGS) $@)

$(builtin-target): $(obj-y) FORCE
	$(call if_changed,link_o_target)

targets += $(builtin-target)
endif # builtin-target
```

builtin-target目标文件通过if_changed变量扩展为cmd_link_o_target用于将所有的obj-y变量指定的
文件链接为对应的builtin.o文件.builtin-target目标依赖于obj-y变量指定的文件.obj-y文件的生成规则
如下所示:

*.o文件
----------------------------------------

### 生成规则

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

如上规则包含了vmlinux-dirs变量指定目录中的Makefile文件，在这些Makefile
文件中会指定obj-y变量，它指定的都是一些*.o目标文件. 这些*.o文件的生成
规则如下所示:

path: scripts/Makefile.build
```
# Built-in and composite module parts
$(obj)/%.o: $(src)/%.c $(recordmcount_source) FORCE
	$(call cmd,force_checksrc)
	$(call if_changed_rule,cc_o_c)
```
cc_o_c由if_changed_rule扩展为rule_cc_o_c函数用来将c源文件编译
为.o目标文件:

path: scripts/Makefile.build
```
cmd_cc_o_c = $(CC) $(c_flags) -c -o $@ $<
...
define rule_cc_o_c
	$(call echo-cmd,checksrc) $(cmd_checksrc)			  \
	$(call echo-cmd,cc_o_c) $(cmd_cc_o_c);				  \
	$(cmd_modversions)						  \
	$(call echo-cmd,record_mcount)					  \
	$(cmd_record_mcount)						  \
	scripts/basic/fixdep $(depfile) $@ '$(call make-cmd,cc_o_c)' >    \
	                                              $(dot-target).tmp;  \
	rm -f $(depfile);						  \
	mv -f $(dot-target).tmp $(dot-target).cmd
endef
```

vmlinux文件
----------------------------------------

```
$ file vmlinux
vmlinux: ELF 32-bit LSB  executable, ARM, EABI5 version 1 (SYSV), statically linked, BuildID[sha1]=e0311821a2c42b58b59aaf83dae3a8be5ff56a10, not stripped
$ arm-none-linux-gnueabi-readelf -h vmlinux
ELF Header:
  Magic:   7f 45 4c 46 01 01 01 00 00 00 00 00 00 00 00 00
  Class:                             ELF32
  Data:                              2's complement, little endian
  Version:                           1 (current)
  OS/ABI:                            UNIX - System V
  ABI Version:                       0
  Type:                              EXEC (Executable file)
  Machine:                           ARM
  Version:                           0x1
  Entry point address:               0xc0008000
  Start of program headers:          52 (bytes into file)
  Start of section headers:          12052856 (bytes into file)
  Flags:                             0x5000202, has entry point, Version5 EABI, soft-float ABI
  Size of this header:               52 (bytes)
  Size of program headers:           32 (bytes)
  Number of program headers:         5
  Size of section headers:           40 (bytes)
  Number of section headers:         32
  Section header string table index: 29
```

vmlinux是标准的Linux下的elf可执行文件。它与其他的可执行文件格式没有任何本质区别, 普通应用程序有
for GNU/Linux 2.6.14的提示，所以想在Linux上直接运行vmlinux是不行的，因为它需要运行在特权模式，
ELF加载器无法加载它。使用arm-linux-readelf可以清晰的看到它的代码段起始地址位于内核空间0xc0008000.
