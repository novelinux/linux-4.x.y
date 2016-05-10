cmd
========================================

编译过的内核可以发现有很多.cmd文件，它们与目标文件相伴而生。
比如目标文件名为xxx，那么相同目录下将可以找到对应的.xxx.cmd文件。
比如init/main.o对应.main.o.cmd; .cmd文件是由名为make-cmd的子命令
生成的，它定义在scripts/Kbuild.include:

make-cmd
----------------------------------------

path: scripts/Kbuild.include
```
...
# Replace >$< with >$$< to preserve $ when reloading the .cmd file
# (needed for make)
# Replace >#< with >\#< to avoid starting a comment in the .cmd file
# (needed for make)
# Replace >'< with >'\''< to be able to enclose the whole string in '...'
# (needed for the shell)
make-cmd = $(call escsq,$(subst \#,\\\#,$(subst $$,$$$$,$(cmd_$(1)))))
...
```

escsq子命令定义如下:

escsq
----------------------------------------

```
squote  := '
...
###
# Escape single quote for use in echo statements
escsq = $(subst $(squote),'\$(squote)',$1)
...
```

cmd
----------------------------------------

path: scripts/Kbuild.include
```
# echo command.
# Short version is used, if $(quiet) equals `quiet_', otherwise full one.
echo-cmd = $(if $($(quiet)cmd_$(1)),\
	echo '  $(call escsq,$($(quiet)cmd_$(1)))$(echo-why)';)

# printing commands
cmd = @$(echo-cmd) $(cmd_$(1))
```

### quiet变量

对应的quiet变量定义如下所示:

path: Makefile
```
...
ifeq ($(KBUILD_VERBOSE),1)
  quiet =
  Q =
else
  quiet=quiet_
  Q = @
endif
...
```

if_changed
----------------------------------------

path: scripts/Kbuild.include
```
# Execute command if command has changed or prerequisite(s) are updated.
#
if_changed = $(if $(strip $(any-prereq) $(arg-check)),                       \
	@set -e;                                                             \
	$(echo-cmd) $(cmd_$(1));                                             \
	printf '%s\n' 'cmd_$@ := $(make-cmd)' > $(dot-target).cmd)
```

if_changed_dep
----------------------------------------

path: scripts/Kbuild.include
```
# Execute the command and also postprocess generated .d dependencies file.
if_changed_dep = $(if $(strip $(any-prereq) $(arg-check) ),                  \
	@set -e;                                                             \
	$(echo-cmd) $(cmd_$(1));                                             \
	scripts/basic/fixdep $(depfile) $@ '$(make-cmd)' > $(dot-target).tmp;\
	rm -f $(depfile);                                                    \
	mv -f $(dot-target).tmp $(dot-target).cmd)
```

if_changed_rule
----------------------------------------

path: scripts/Kbuild.include
```
...
# Usage: $(call if_changed_rule,foo)
# Will check if $(cmd_foo) or any of the prerequisites changed,
# and if so will execute $(rule_foo).
if_changed_rule = $(if $(strip $(any-prereq) $(arg-check) ),                 \
	@set -e;                                                             \
	$(rule_$(1)))
...
```

接下来看一个实际的应用，这个应用是将对应的c源代码文件编译成.o目标文件.

```
$(obj)/%.o: $(src)/%.c $(recordmcount_source) FORCE
	$(call cmd,force_checksrc)
	$(call if_changed_rule,cc_o_c)
```

这里会执行if_changed_rule表达式，并且cc_o_c将被传得给它。
if_changed_rule扩展参数后的表达式如下：

```
$(if $(strip $(any-prereq) $(arg-check)), @set -e; $(rule_cc_o_c)))
```

### any-prereq

path: scripts/Kbuild.include
```
# Find any prerequisites that is newer than target or that does not exist.
# PHONY targets skipped in both cases.
any-prereq = $(filter-out $(PHONY),$?) $(filter-out $(PHONY) $(wildcard $^),$^)
```

any-prereq用来收集目标文件的依赖文件，找出更新的依赖文件或者尚不存在
需要编译时生成的依赖,自动化变量$?代表所有比目标还要新的依赖文件;
$^则表示所有的依赖文件。filter-out反过滤函数将$?中的所有伪目标过滤掉。
第二个反过滤函数过滤出所有依赖文件中已经存在的文件以及伪目标，有些依赖
需要在编译时自动创建，比如vmlinux依赖的arch/arm/kernel/vmlinux.lds文件。

### arg-check

path: scripts/Kbuild.include
```
...
ifneq ($(KBUILD_NOCMDDEP),1)
# Check if both arguments has same arguments. Result is empty string if equal.
# User may override this check using make KBUILD_NOCMDDEP=1
arg-check = $(strip $(filter-out $(cmd_$(1)), $(cmd_$@)) \
                    $(filter-out $(cmd_$@),   $(cmd_$(1))) )
else
arg-check = $(if $(strip $(cmd_$@)),,1)
endif
...
```

arg-check用来检测此次编译时所用命令及参数是否和上次所用参数一致.
$@表示目标文件.在 arg-check中，首先使用
$(filter-out $(cmd_$(1)), $(cmd_$@))从上一次的编译命令和参数中滤除掉
此次编译使用的命令和参数，再进行一次反过滤。正反过滤的原因是，
filter-out 函数在过滤时，如果第 2 个命令和参数是第1个命令和参数的
子集或者是相同，那么返回空；所以，在第1次过滤时如果返回为空，那么
cmd_$@ 可能是等于 cmd_$(1) 的，也可能是它的子集，所以只有当再次反过
来做过滤时发现返回为空，那么才能判断两次编译的参数是相等的，否则是
不等的。如果返回结果不为空，说明编译参数发生了变化：
* 1.参数增加，那么第二次过滤不为空;
* 2.参数减少，那么第一次过滤不为空；
* 3.参数顺序变化，第一次和第二次都不为空。

any-prereq完成了依赖的检查，arg-check完成了命令和参数的检查，
只要有一种情况发生，那么if语句 就返回真，@set -e; $(rule_cc_o_c)
就得到执行。set –e迫使$(rule_cc_o_c)在返回非0值时立刻返回。