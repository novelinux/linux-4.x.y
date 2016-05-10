LINUX kernel debug
========================================

With qemu debug
----------------------------------------

https://github.com/yudatun/Documentation/tree/master/arch/qemu/README.md

Debugging
----------------------------------------

1.Start kernel

```
$ qemu-system-arm -kernel boot/kernel.img -cpu arm1176 -m 256 -M versatilepb -no-reboot -serial stdio -append "root=/dev/sda2 panic=1 rootfstype=ext4 rw init=/bin/bash" -hda 2015-05-05-raspbian-wheezy.img -s -S
```

Note: kernel build needs choose "Compile the kernel with debug info.".

2.Debugging

```
$ arm-eabi-gdb vmlinux
GNU gdb (GDB) 7.9
Copyright (C) 2015 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.  Type "show copying"
and "show warranty" for details.
This GDB was configured as "--host=x86_64-linux-gnu --target=arm-eabi".
Type "show configuration" for configuration details.
For bug reporting instructions, please see:
<http://www.gnu.org/software/gdb/bugs/>.
Find the GDB manual and other documentation resources online at:
<http://www.gnu.org/software/gdb/documentation/>.
For help, type "help".
Type "apropos word" to search for commands related to "word"...
Reading symbols from vmlinux...done.
(gdb) target remote :1234
Remote debugging using :1234
__vectors_start () at /home/liminghao/big/leeminghao/yudatun-qemu/kernel/linux-4.3/arch/arm/kernel/entry-armv.S:1237
1237               W(b) vector_rst
(gdb)
```