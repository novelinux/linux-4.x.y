TEXT_OFFSET
========================================

The byte offset of the kernel image in RAM from the start of RAM.

Virtual start address of kernel, normally PAGE_OFFSET + 0x8000.
This is where the kernel image ends up.  With the latest kernels,
it must be located at 32768 bytes into a 128MB region.  Previous
kernels placed a restriction of 256MB here.

path: arch/arm/Makefile
```
# The byte offset of the kernel image in RAM from the start of RAM.
textofs-y	:= 0x00008000
...
TEXT_OFFSET := $(textofs-y)
```
