EXEC同DYN格式区别
========================================

exec_elf是由arm-none-linux-gnueabi-gcc编译而成的EXEC类型的ELF格式文件;
dyn_elf是由arm-linux-androideabi-gcc编译而成的DYN类型的ELF格式文件.

对于类型为EXEC的可执行程序映像而言，装入的起点就是映像自己LOAD段
提供的地址vaddr。在这里查看program header同maps为0x8000.

对于类型为DYN(即共享库)，那么即使装入地址固定也要加上一个偏移量，
计算方法: ELF_ET_DYN_BASE为(TASK_SIZE / 3 * 2)，所以这是2GB边界，
而ELF_PAGESTART表示按页面边界对齐.

```
ELF_PAGESTART(ELF_ET_DYN_BASE - vaddr)
```

vaddr为LOAD段指定的vaddr起始地址.

elf header
----------------------------------------

### exec_elf

```
$ arm-none-linux-gnueabi-readelf -h exec_elf
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
  Entry point address:               0x8440
  Start of program headers:          52 (bytes into file)
  Start of section headers:          2580 (bytes into file)
  Flags:                             0x5000202, has entry point, Version5 EABI, soft-float ABI
  Size of this header:               52 (bytes)
  Size of program headers:           32 (bytes)
  Number of program headers:         8
  Size of section headers:           40 (bytes)
  Number of section headers:         31
  Section header string table index: 28
```

### dyn_elf

```
$ arm-none-linux-gnueabi-readelf -h dyn_elf
ELF Header:
  Magic:   7f 45 4c 46 01 01 01 00 00 00 00 00 00 00 00 00
  Class:                             ELF32
  Data:                              2's complement, little endian
  Version:                           1 (current)
  OS/ABI:                            UNIX - System V
  ABI Version:                       0
  Type:                              DYN (Shared object file)
  Machine:                           ARM
  Version:                           0x1
  Entry point address:               0x360
  Start of program headers:          52 (bytes into file)
  Start of section headers:          7052 (bytes into file)
  Flags:                             0x5000000, Version5 EABI
  Size of this header:               52 (bytes)
  Size of program headers:           32 (bytes)
  Number of program headers:         8
  Size of section headers:           40 (bytes)
  Number of section headers:         33
  Section header string table index: 32
```

programe header
----------------------------------------

### exec_elf

```
$ arm-none-linux-gnueabi-readelf -l exec_elf
Elf file type is EXEC (Executable file)
Entry point 0x8440
There are 8 program headers, starting at offset 52

Program Headers:
  Type           Offset   VirtAddr   PhysAddr   FileSiz MemSiz  Flg Align
  EXIDX          0x0006e8 0x000086e8 0x000086e8 0x00050 0x00050 R   0x4
  PHDR           0x000034 0x00008034 0x00008034 0x00100 0x00100 R E 0x4
  INTERP         0x000134 0x00008134 0x00008134 0x00013 0x00013 R   0x1
      [Requesting program interpreter: /lib/ld-linux.so.3]
  LOAD           0x000000 0x00008000 0x00008000 0x0073c 0x0073c R E 0x8000
  LOAD           0x00073c 0x0001073c 0x0001073c 0x0012c 0x00130 RW  0x8000
  DYNAMIC        0x000748 0x00010748 0x00010748 0x000f0 0x000f0 RW  0x4
  NOTE           0x000148 0x00008148 0x00008148 0x00020 0x00020 R   0x4
  GNU_STACK      0x000000 0x00000000 0x00000000 0x00000 0x00000 RW  0x10

 Section to Segment mapping:
  Segment Sections...
   00     .ARM.exidx
   01
   02     .interp
   03     .interp .note.ABI-tag .hash .dynsym .dynstr .gnu.version .gnu.version_r .rel.dyn .rel.plt .init .plt .text .fini .rodata .ARM.extab .ARM.exidx .eh_frame
   04     .init_array .fini_array .jcr .dynamic .got .data .bss
   05     .dynamic
   06     .note.ABI-tag
   07
```

### dyn_elf

```
$ arm-none-linux-gnueabi-readelf -l dyn_elf

Elf file type is DYN (Shared object file)
Entry point 0x360
There are 8 program headers, starting at offset 52

Program Headers:
  Type           Offset   VirtAddr   PhysAddr   FileSiz MemSiz  Flg Align
  PHDR           0x000034 0x00000034 0x00000034 0x00100 0x00100 R   0x4
  INTERP         0x000134 0x00000134 0x00000134 0x00013 0x00013 R   0x1
      [Requesting program interpreter: /system/bin/linker]
  LOAD           0x000000 0x00000000 0x00000000 0x00494 0x00494 R E 0x1000
  LOAD           0x000ec0 0x00001ec0 0x00001ec0 0x00140 0x00144 RW  0x1000
  DYNAMIC        0x000ed8 0x00001ed8 0x00001ed8 0x000f8 0x000f8 RW  0x4
  GNU_STACK      0x000000 0x00000000 0x00000000 0x00000 0x00000 RW  0
  EXIDX          0x00045c 0x0000045c 0x0000045c 0x00010 0x00010 R   0x4
  GNU_RELRO      0x000ec0 0x00001ec0 0x00001ec0 0x00140 0x00140 RW  0x4

 Section to Segment mapping:
  Segment Sections...
   00
   01     .interp
   02     .interp .dynsym .dynstr .hash .rel.dyn .rel.plt .plt .text .note.android.ident .ARM.extab .ARM.exidx .rodata
   03     .preinit_array .init_array .fini_array .dynamic .got .bss
   04     .dynamic
   05
   06     .ARM.exidx
   07     .preinit_array .init_array .fini_array .dynamic .got
```

maps
----------------------------------------

### exec_elf

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/mm/src/vm_layout/exec_elf.maps

### dyn_elf

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/mm/src/vm_layout/dyn_elf_6163.maps
