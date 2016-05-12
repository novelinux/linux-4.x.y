Memory Layout
========================================

ARM64系统地址空间的设置在某些方面比ARM容易，但在另一些方面要困难。虽然64位地址空间避免了古怪的
高端内存域，但有另一个因素使情况复杂化。64位地址空间的跨度太大，当前没有什么应用程序需要这个。
因此，当前只实现了一个比较小的物理地址空间，地址字宽度为CONFIG_ARM64_VA_BITS位。这在不失灵活性的
前提下，简化并加速了地址转换。

### gemini

```
CONFIG_ARM64_VA_BITS=39
```

gemini virtual memory layout
----------------------------------------

```
[    0.000000] Memory: 2579804K/2930556K available (12830K kernel code, 2456K rwdata, 8628K rodata, 592K init, 4575K bss, 350752K reserved)
[    0.000000] Virtual kernel memory layout:
[    0.000000]     vmalloc : 0xffffff8000000000 - 0xffffffba3fff0000   (   232 GB)
[    0.000000]     vmemmap : 0xffffffba40000000 - 0xffffffbfc0000000   (    22 GB maximum)
[    0.000000]               0xffffffba45800000 - 0xffffffba4db17a00   (   131 MB actual)
[    0.000000]     PCI I/O : 0xffffffbffa000000 - 0xffffffbffb000000   (    16 MB)
[    0.000000]     fixed   : 0xffffffbffbdfe000 - 0xffffffbffbdff000   (     4 KB)
[    0.000000]     modules : 0xffffffbffc000000 - 0xffffffc000000000   (    64 MB)
[    0.000000]     memory  : 0xffffffc000000000 - 0xffffffc0beae0000   (  3050 MB)
[    0.000000]       .init : 0xffffffc001576000 - 0xffffffc00160a000   (   592 KB)
[    0.000000]       .text : 0xffffffc000080000 - 0xffffffc001575954   ( 21463 KB)
[    0.000000]       .data : 0xffffffc001614000 - 0xffffffc00187a350   (  2457 KB)
```
