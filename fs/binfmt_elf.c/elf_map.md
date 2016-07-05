elf_map
========================================

Source:
----------------------------------------

elf_map用于建立进程虚拟地址空间与目标映像文件中某个连续区间之间的映射.
其中, 传入参数信息如下所示:

* filep - 指向目标映像文件.
* addr - 装入地址.
* eppnt - 指明装入段(PT_LOAD)的程序头信息.
* prot - 指明装入段的权限.
* type - 指明映射标志.
* total_size - 表明elf image文件的大小.

```
static unsigned long elf_map(struct file *filep, unsigned long addr,
      struct elf_phdr *eppnt, int prot, int type,
      unsigned long total_size)
{
   unsigned long map_addr;
   /* 1.eppnt->p_vaddr给出了段(PT_LOAD)的数据映射到虚拟地址空间中的位置.
   * eppnt->p_filesz指定了段在二进制文件中的长度(单位字节).
   */
   unsigned long size = eppnt->p_filesz + ELF_PAGEOFFSET(eppnt->p_vaddr);
   /* 2.eppnt->p_offset给出了所述段在文件中的偏移量(单位为字节). */
   unsigned long off = eppnt->p_offset - ELF_PAGEOFFSET(eppnt->p_vaddr);
   addr = ELF_PAGESTART(addr);
   size = ELF_PAGEALIGN(size);

   /* mmap() will return -EINVAL if given a zero size, but a
    * segment with zero filesize is perfectly valid */
   if (!size)
      return addr;

   /*
   * total_size is the size of the ELF (interpreter) image.
   * The _first_ mmap needs to know the full size, otherwise
   * randomization might put this image into an overlapping
   * position with the ELF binary image. (since size < total_size)
   * So we first map the 'big' image - and unmap the remainder at
   * the end. (which unmap is needed for ELF images with holes.)
   */
   if (total_size) {
      total_size = ELF_PAGEALIGN(total_size);
      map_addr = vm_mmap(filep, addr, total_size, prot, type, off);
      if (!BAD_ADDR(map_addr))
         vm_munmap(map_addr+size, total_size-size);
   } else
      map_addr = vm_mmap(filep, addr, size, prot, type, off);

   return(map_addr);
}
```

### 重新计算PT_LOAD段装入地址，段大小和偏移量.

#### EXEC

mm/src/vm_layout/exec_elf这个elf格式文件的type是EXEC类型的.

针对我们a.out这个可执行文件来说其PT_LOAD段加载的信息如下所示:

```
Type           Offset   VirtAddr   PhysAddr   FileSiz MemSiz  Flg Align
...
LOAD           0x000000 0x00008000 0x00008000 0x0073c 0x0073c R E 0x8000
LOAD           0x00073c 0x0001073c 0x0001073c 0x0012c 0x00130 RW  0x8000
```

经过elf_map重新计算后得到的值如下所示:

##### LOAD1

```
addr=0x8000
size=0x1000
off=0x0
```

##### LOAD2

```
addr=0x10000
size=0x1000
off=0x0
```

#### DYN

mm/src/vm_layout/dyn_elf这个elf格式可执行文件的type是DYN类型的.
针对我们dyn_elf这个可执行文件来说其PT_LOAD段加载的信息如下所示:

```
$ arm-linux-androideabi-readelf -l dyn_elf

Program Headers:
  Type           Offset   VirtAddr   PhysAddr   FileSiz MemSiz  Flg Align
  ...
  INTERP         0x000134 0x00000134 0x00000134 0x00013 0x00013 R   0x1
      [Requesting program interpreter: /system/bin/linker]
  LOAD           0x000000 0x00000000 0x00000000 0x00494 0x00494 R E 0x1000
  LOAD           0x000ec0 0x00001ec0 0x00001ec0 0x00140 0x00144 RW  0x1000
  ...
```

经过elf_map重新计算后得到的值如下所示:

##### LOAD1

```
addr=0x0
size=0x1000
off=0x0
map_addr=0xb6f84000
```

##### LOAD2

```
addr=0xb6f85000
size=0x1000
off=0x0
map_addr=0xb6f85000
```

对应maps中信息如下所示:

```
...
b6f84000-b6f85000 r-xp 00000000 b3:15 2178       /system/bin/dyn_elf
b6f85000-b6f86000 r--p 00000000 b3:15 2178       /system/bin/dyn_elf
...
```

接下来调用vm_mmap函数来进行映射操作:

vm_mmap
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/util_c/vm_mmap.md
