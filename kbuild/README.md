Linux内核编译
========================================

我们以编译适合ARM Cortex A9芯片的Linux内核image为例来描述Linux内核image的编译过程.

编译命令
-----------------------------------------

```
$ export ARCH=arm
$ export CROSS_COMPILE=arm-none-eabi-
$ make vexpress_defconfig
$ make zImage
```

zImage编译过程
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/kbuild/zImage.md

log
----------------------------------------

### make vexpress_defconfig

https://github.com/novelinux/linux-4.x.y/tree/master/kbuild/log/vexpress_defconfig.log

### make zImage

https://github.com/novelinux/linux-4.x.y/tree/master/kbuild/log/zImage.log