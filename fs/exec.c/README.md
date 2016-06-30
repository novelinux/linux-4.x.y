exec
========================================

通过用新代码替换现存程序，即可启动新程序。Linux提供的execve系统调用可用于该目的。

Data Structure
----------------------------------------

### struct linux_binprm

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/binfmts.h/struct_linux_binprm.md

### struct linux_binfmt

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/binfmts.h/struct_linux_binfmt.md

APIS
----------------------------------------

https://github.com/novelinux/system_calls/blob/master/exec/README.md

该系统调用的入口点是体系结构相关的sys_execve函数:

https://github.com/novelinux/linux-4.x.y/tree/master/fs/exec.c/sys_execve.md