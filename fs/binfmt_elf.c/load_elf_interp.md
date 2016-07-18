load_elf_interp
========================================

load_elf_interp是用来加载解释器文件映像，具体实现如下所示:

Arguments
----------------------------------------

path: fs/binfmt_elf.c
```
/* This is much more generalized than the library routine read function,
   so we keep this separate.  Technically the library read function
   is only provided so that we can read a.out libraries that have
   an ELF header */

static unsigned long load_elf_interp(struct elfhdr *interp_elf_ex,
        struct file *interpreter, unsigned long *interp_map_addr,
        unsigned long no_base)
{
    struct elf_phdr *elf_phdata;
    struct elf_phdr *eppnt;
    unsigned long load_addr = 0;
    int load_addr_set = 0;
    unsigned long last_bss = 0, elf_bss = 0;
    unsigned long error = ~0UL;
    unsigned long total_size;
    int retval, i, size;
```

* interp_elf_ex: 指向解释器elf header信息.
* interpreter: 用来描述解释器文件的struct file数据结构(在这里就是是linker文件的描述符).
* interp_map_addr: 是解释器文件的映射首地址.
* no_base: 是进程加载的elf二进制文件代码段的装入首地址.
* interp_elf_phdata: 是解释器文件的program headers信息.

Check
----------------------------------------

检查解释器文件的类型和体系结构是否合法等.

```
    /* First of all, some simple consistency checks */
    if (interp_elf_ex->e_type != ET_EXEC &&
        interp_elf_ex->e_type != ET_DYN)
        goto out;
    if (!elf_check_arch(interp_elf_ex))
        goto out;
    if (!interpreter->f_op->mmap)
        goto out;

    /*
     * If the size of this structure has changed, then punt, since
     * we will be doing the wrong thing.
     */
    if (interp_elf_ex->e_phentsize != sizeof(struct elf_phdr))
        goto out;
    if (interp_elf_ex->e_phnum < 1 ||
        interp_elf_ex->e_phnum > 65536U / sizeof(struct elf_phdr))
        goto out;

    /* Now read in all of the header information */
    size = sizeof(struct elf_phdr) * interp_elf_ex->e_phnum;
    if (size > ELF_MIN_ALIGN)
        goto out;
    elf_phdata = kmalloc(size, GFP_KERNEL);
    if (!elf_phdata)
        goto out;
```

kernel_read
----------------------------------------

```
    retval = kernel_read(interpreter, interp_elf_ex->e_phoff,
                 (char *)elf_phdata, size);
    error = -EIO;
    if (retval != size) {
        if (retval < 0)
            error = retval;
        goto out_close;
    }
```

total_mapping_size
----------------------------------------

```
    total_size = total_mapping_size(elf_phdata, interp_elf_ex->e_phnum);
    if (!total_size) {
        error = -EINVAL;
        goto out_close;
    }
```

total_mapping_size实现如下所示:

https://github.com/novelinux/linux-4.x.y/tree/master/fs/binfmt_elf.c/total_mapping_size.md

经过total_mapping_size计算出的size值大小如下:

```
total_size=63228
```

Program Headers (PT_LOAD)
----------------------------------------

加载解释器文件的PT_LOAD段

```
    eppnt = elf_phdata;
    for (i = 0; i < interp_elf_ex->e_phnum; i++, eppnt++) {
        if (eppnt->p_type == PT_LOAD) {
            int elf_type = MAP_PRIVATE | MAP_DENYWRITE;
            int elf_prot = 0;
            unsigned long vaddr = 0;
            unsigned long k, map_addr;

            if (eppnt->p_flags & PF_R)
                    elf_prot = PROT_READ;
            if (eppnt->p_flags & PF_W)
                elf_prot |= PROT_WRITE;
            if (eppnt->p_flags & PF_X)
                elf_prot |= PROT_EXEC;
            vaddr = eppnt->p_vaddr;
            if (interp_elf_ex->e_type == ET_EXEC || load_addr_set)
                elf_type |= MAP_FIXED;
            else if (no_base && interp_elf_ex->e_type == ET_DYN)
                load_addr = -vaddr;

            map_addr = elf_map(interpreter, load_addr + vaddr,
                    eppnt, elf_prot, elf_type, total_size);
            total_size = 0;
            if (!*interp_map_addr)
                *interp_map_addr = map_addr;
            error = map_addr;
            if (BAD_ADDR(map_addr))
                goto out_close;

            if (!load_addr_set &&
                interp_elf_ex->e_type == ET_DYN) {
                load_addr = map_addr - ELF_PAGESTART(vaddr);
                load_addr_set = 1;
            }

            /*
             * Check to see if the section's size will overflow the
             * allowed task size. Note that p_filesz must always be
             * <= p_memsize so it's only necessary to check p_memsz.
             */
            k = load_addr + eppnt->p_vaddr;
            if (BAD_ADDR(k) ||
                eppnt->p_filesz > eppnt->p_memsz ||
                eppnt->p_memsz > TASK_SIZE ||
                TASK_SIZE - eppnt->p_memsz < k) {
                error = -ENOMEM;
                goto out_close;
            }

            /*
             * Find the end of the file mapping for this phdr, and
             * keep track of the largest address we see for this.
             */
            k = load_addr + eppnt->p_vaddr + eppnt->p_filesz;
            if (k > elf_bss)
                elf_bss = k;

            /*
             * Do the same thing for the memory mapping - between
             * elf_bss and last_bss is the bss section.
             */
            k = load_addr + eppnt->p_memsz + eppnt->p_vaddr;
            if (k > last_bss)
                last_bss = k;
        }
    }
```

```
    if (last_bss > elf_bss) {
        /*
         * Now fill out the bss section.  First pad the last page up
         * to the page boundary, and then perform a mmap to make sure
         * that there are zero-mapped pages up to and including the
         * last bss page.
         */
        if (padzero(elf_bss)) {
            error = -EFAULT;
            goto out_close;
        }

        /* What we have mapped so far */
        elf_bss = ELF_PAGESTART(elf_bss + ELF_MIN_ALIGN - 1);

        /* Map the last of the bss segment */
        error = vm_brk(elf_bss, last_bss - elf_bss);
        if (BAD_ADDR(error))
            goto out_close;
    }

    error = load_addr;

out_close:
    kfree(elf_phdata);
out:
    return error;
}
```

3.total_mapping_size
----------------------------------------

计算映射区域总的大小.

```
    ...
    total_size = total_mapping_size(interp_elf_phdata,
                    interp_elf_ex->e_phnum);
    if (!total_size) {
        error = -EINVAL;
        goto out;
    }
    ...
```


```
            /* 2.通过elf_map为解释器分配一块虚拟内存映射区域,map_addr保存linker文件映射的首地址
             * 并将其作为返回值保存到interp_map_addr中去.
             */
            map_addr = elf_map(interpreter, load_addr + vaddr,
                    eppnt, elf_prot, elf_type, total_size);
            total_size = 0;
            if (!*interp_map_addr)
                *interp_map_addr = map_addr;
            error = map_addr;
            if (BAD_ADDR(map_addr))
                goto out;

            /* 如果是DYN类型，则重新计算装载地址存放到load_addr中去. */
            if (!load_addr_set &&
                interp_elf_ex->e_type == ET_DYN) {
                load_addr = map_addr - ELF_PAGESTART(vaddr);
                load_addr_set = 1;
            }

            /*
             * Check to see if the section's size will overflow the
             * allowed task size. Note that p_filesz must always be
             * <= p_memsize so it's only necessary to check p_memsz.
             */
            k = load_addr + eppnt->p_vaddr;
            if (BAD_ADDR(k) ||
                eppnt->p_filesz > eppnt->p_memsz ||
                eppnt->p_memsz > TASK_SIZE ||
                TASK_SIZE - eppnt->p_memsz < k) {
                error = -ENOMEM;
                goto out;
            }

            /*
             * Find the end of the file mapping for this phdr, and
             * keep track of the largest address we see for this.
             */
            k = load_addr + eppnt->p_vaddr + eppnt->p_filesz;
            if (k > elf_bss)
                elf_bss = k;

            /*
             * Do the same thing for the memory mapping - between
             * elf_bss and last_bss is the bss section.
             */
            k = load_addr + eppnt->p_memsz + eppnt->p_vaddr;
            if (k > last_bss)
                last_bss = k;
        }
    }
    ...
```

在这里我们elf文件的解释器是linker,其header信息如下所示:

https://github.com/leeminghao/doc-linux/blob/master/linker/AndroidLinker/src/linker/linker_header.md

其共有两个LOAD段经过elf_map得到的映射信息如下所示:

### PT_LOAD1

```
addr=0
size=d000
off=0
map_addr=b6f74000
```

### PT_LOAD2

```
addr=b6f81000
size=2000
off=c000
map_addr=b6f81000
```

### load_addr

最终返回给上级调用函数的load_addr值如下所示:

```
load_addr=b6f74000
```

### last_bss vs elf_bss

此时计算出的last_bss同elf_bss地址值分别如下所示:

```
elf_bss=b6f82190
last_bss=b6f836fc
```

5.映射解释器bss段
----------------------------------------

```
    ...
    if (last_bss > elf_bss) {
        /*
         * Now fill out the bss section.  First pad the last page up
         * to the page boundary, and then perform a mmap to make sure
         * that there are zero-mapped pages up to and including the
         * last bss page.
         */
        if (padzero(elf_bss)) {
            error = -EFAULT;
            goto out;
        }

        /* What we have mapped so far */
        elf_bss = ELF_PAGESTART(elf_bss + ELF_MIN_ALIGN - 1);

        /* Map the last of the bss segment */
        error = vm_brk(elf_bss, last_bss - elf_bss);
        if (BAD_ADDR(error))
            goto out;
    }
    ...
```

通过ELF_PAGESTART计算得到的elf_bss值为b6f83000

elf_bss和last_bss分别是bss和堆的起始地址,而因为bss与堆是前后相连的，所以它们之间的距离正好是
bss区的大小. 所以它们之间的距离正好是bss段的大小. vm_brk的两个参数正好是bss段的起始地址和长度.

vm_brk的具体实现如下所示:

https://github.com/novelinux/linux-4.x.y/tree/master/mm/mmap_c/vm_brk.md
