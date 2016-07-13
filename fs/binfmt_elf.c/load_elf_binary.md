load_elf_binary
========================================

load_elf_binary用来装载一个elf格式的二进制文件，其具体实现如下所示:

Arguments
----------------------------------------

path: fs/binfmt_elf.c
```
static int load_elf_binary(struct linux_binprm *bprm)
{
    struct file *interpreter = NULL; /* to shut gcc up */
     unsigned long load_addr = 0, load_bias = 0;
    int load_addr_set = 0;
    char * elf_interpreter = NULL;
    unsigned long error;
    struct elf_phdr *elf_ppnt, *elf_phdata, *interp_elf_phdata = NULL;
    unsigned long elf_bss, elf_brk;
    int retval, i;
    unsigned long elf_entry;
    unsigned long interp_load_addr = 0;
    unsigned long start_code, end_code, start_data, end_data;
    unsigned long reloc_func_desc __maybe_unused = 0;
    int executable_stack = EXSTACK_DEFAULT;
    struct pt_regs *regs = current_pt_regs();
```

kmalloc (loc)
----------------------------------------

```
    struct {
        struct elfhdr elf_ex;
        struct elfhdr interp_elf_ex;
    } *loc;
    struct arch_elf_state arch_state = INIT_ARCH_ELF_STATE;

    loc = kmalloc(sizeof(*loc), GFP_KERNEL);
    if (!loc) {
        retval = -ENOMEM;
        goto out_ret;
    }
```

为loc分配空间,loc变量由两个struct elfhdr结构的变量elf_ex和
interp_elf_ex组成,其中elfhdr是宏.

ELF Header
----------------------------------------

```
    /* Get the exec-header */
    /* bprm 的成员变量buf中存储可执行文件的前128个字节 */
    loc->elf_ex = *((struct elfhdr *)bprm->buf);

    retval = -ENOEXEC;
    /* First of all, some simple consistency checks */
    /* 校验是否是elf header. */
    if (memcmp(loc->elf_ex.e_ident, ELFMAG, SELFMAG) != 0)
        goto out;

    /* 校验二进制文件的type是否允许是允许load的type. */
    if (loc->elf_ex.e_type != ET_EXEC && loc->elf_ex.e_type != ET_DYN)
        goto out;

    /* 校验体系结构arch是否合法. */
    if (!elf_check_arch(&loc->elf_ex))
        goto out;
    if (!bprm->file->f_op->mmap)
        goto out;
```

load_elf_phdrs
----------------------------------------

```
    elf_phdata = load_elf_phdrs(&loc->elf_ex, bprm->file);
    if (!elf_phdata)
        goto out;

    // 将读出的程序头指针指向elf_ppnt
    elf_ppnt = elf_phdata;
    elf_bss = 0;
    elf_brk = 0;

    /* 可执行代码的虚拟地址空间区域，其开始和结束分别通过
     * start_code和end_code标记
     */
    start_code = ~0UL;
    end_code = 0;
    start_data = 0;
    end_data = 0;
```

加载Program Header.

https://github.com/novelinux/linux-4.x.y/tree/master/fs/binfmt_elf_c/load_elf_phdrs.md

Program Headers (PT_INTERP)
----------------------------------------

```
    for (i = 0; i < loc->elf_ex.e_phnum; i++) {
        if (elf_ppnt->p_type == PT_INTERP) {
            /* This is the program interpreter used for
             * shared libraries - for now assume that this
             * is an a.out format binary
             */
            retval = -ENOEXEC;
            if (elf_ppnt->p_filesz > PATH_MAX ||
                elf_ppnt->p_filesz < 2)
                goto out_free_ph;

            retval = -ENOMEM;
            elf_interpreter = kmalloc(elf_ppnt->p_filesz,
                          GFP_KERNEL);
            if (!elf_interpreter)
                goto out_free_ph;

            /* 从二进制文件中读出对应的INTERP段. INTERP段中存这对应
             * 链接器的名称.
             */
            retval = kernel_read(bprm->file, elf_ppnt->p_offset,
                         elf_interpreter,
                         elf_ppnt->p_filesz);
            if (retval != elf_ppnt->p_filesz) {
                if (retval >= 0)
                    retval = -EIO;
                goto out_free_interp;
            }
            /* make sure path is NULL terminated */
            retval = -ENOEXEC;
            if (elf_interpreter[elf_ppnt->p_filesz - 1] != '\0')
                goto out_free_interp;

            /* 调用open_exec打开对应链接器文件并保存为一个struct file
             * 的结构.
             */
            interpreter = open_exec(elf_interpreter);
            retval = PTR_ERR(interpreter);
            if (IS_ERR(interpreter))
                goto out_free_interp;

            /*
             * If the binary is not readable then enforce
             * mm->dumpable = 0 regardless of the interpreter's
             * permissions.
             */
            would_dump(bprm, interpreter);

            /* Get the exec headers */
            retval = kernel_read(interpreter, 0,
                         (void *)&loc->interp_elf_ex,
                         sizeof(loc->interp_elf_ex));
            if (retval != sizeof(loc->interp_elf_ex)) {
                if (retval >= 0)
                    retval = -EIO;
                goto out_free_dentry;
            }

            break;
        }
        elf_ppnt++;
    }
```

INTERP用于指定在程序已经从可执行文件映射到内存之后，必须调用的解释器.
在这里解释器指的是这样一个程序: 通过链接其它库，来满足为解决的引用.
在这里/system/bin/linker用于在虚拟地址空间中插入程序运行所需的动态库.

```
INTERP         0x000134 0x00000134 0x00000134 0x00013 0x00013 R   0x1
      [Requesting program interpreter: /system/bin/linker]
```

Program Headers (GNU_STACK, LOPROC, HIPROC)
----------------------------------------

```
    elf_ppnt = elf_phdata;
    for (i = 0; i < loc->elf_ex.e_phnum; i++, elf_ppnt++)
        switch (elf_ppnt->p_type) {
        case PT_GNU_STACK:
            if (elf_ppnt->p_flags & PF_X)
                executable_stack = EXSTACK_ENABLE_X;
            else
                executable_stack = EXSTACK_DISABLE_X;
            break;

        case PT_LOPROC ... PT_HIPROC:
            retval = arch_elf_pt_proc(&loc->elf_ex, elf_ppnt,
                          bprm->file, false,
                          &arch_state);
            if (retval)
                goto out_free_dentry;
            break;
        }
```

elf_interpreter
----------------------------------------

```
    /* Some simple consistency checks for the interpreter */
    if (elf_interpreter) {
        retval = -ELIBBAD;
        /* Not an ELF interpreter */
        /* 1.检查解释器文件是否是elf格式文件. */
        if (memcmp(loc->interp_elf_ex.e_ident, ELFMAG, SELFMAG) != 0)
            goto out_free_dentry;
        /* Verify the interpreter has a valid arch */
        if (!elf_check_arch(&loc->interp_elf_ex))
            goto out_free_dentry;

        /* Load the interpreter program headers */
        interp_elf_phdata = load_elf_phdrs(&loc->interp_elf_ex,
                           interpreter);
        if (!interp_elf_phdata)
            goto out_free_dentry;

        /* Pass PT_LOPROC..PT_HIPROC headers to arch code */
        elf_ppnt = interp_elf_phdata;
        for (i = 0; i < loc->interp_elf_ex.e_phnum; i++, elf_ppnt++)
            switch (elf_ppnt->p_type) {
            case PT_LOPROC ... PT_HIPROC:
                retval = arch_elf_pt_proc(&loc->interp_elf_ex,
                              elf_ppnt, interpreter,
                              true, &arch_state);
                if (retval)
                    goto out_free_dentry;
                break;
            }
    }
```

arch_check_elf
----------------------------------------

```
    /*
     * Allow arch code to reject the ELF at this point, whilst it's
     * still possible to return an error to the code that invoked
     * the exec syscall.
     */
    retval = arch_check_elf(&loc->elf_ex,
                !!interpreter, &loc->interp_elf_ex,
                &arch_state);
    if (retval)
        goto out_free_dentry;
```

目前改实现为空. 目的是提供最后一次机会来拒绝加载对应的ELF文件.

flush_old_exec
----------------------------------------

```
    /* Flush all traces of the currently running executable */
    retval = flush_old_exec(bprm);
    if (retval)
        goto out_free_dentry;
```

在bprm_mm_init函数中,我们专门为可执行的二进制文件申请了一个地址空间，
使用mm_struct来表示，这个地址空间用来替换当前进程的地址空间，
flush_old_exec函数的作用就是用来替换当前进程地址空间的.具体实现如下所示:

https://github.com/novelinux/linux-4.x.y/tree/master/fs/exec.c/flush_old_exec.md

Set current (personality, flags)
----------------------------------------

```
    /* Do this immediately, since STACK_TOP as used in setup_arg_pages
       may depend on the personality.  */
    SET_PERSONALITY2(loc->elf_ex, &arch_state);
    if (elf_read_implies_exec(loc->elf_ex, executable_stack))
        current->personality |= READ_IMPLIES_EXEC;

    /* 检查是否需要设置进程的PF_RANDOMIZE标志，如果设置了改标志，
     * 则内核不会为栈和内存映射的起点选择固定位置，而是每次新进程
     * 启动的时候随机改变这些值的设置. 引入这项的目的是使得攻击因
     * 缓冲区移除导致安全漏洞更加困难.
     */
    if (!(current->personality & ADDR_NO_RANDOMIZE) && randomize_va_space)
        current->flags |= PF_RANDOMIZE;
```

randomize_va_space的描述如下所示:

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/mm.h/randomize_va_space.md

setup_new_exec
----------------------------------------

```
    setup_new_exec(bprm);
```

setup_new_exec函数用来设置进程虚拟地址空间的布局.

https://github.com/novelinux/linux-4.x.y/tree/master/fs/exec.c/setup_new_exec.md

setup_arg_pages
----------------------------------------

```
    /* Do this so that we can load the interpreter, if need be.  We will
       change some of these later */
    retval = setup_arg_pages(bprm, randomize_stack_top(STACK_TOP),
                 executable_stack);
    if (retval < 0)
        goto out_free_dentry;


```

setup_arg_pages函数用来重新调整当前进程的栈区域位置，权限，大小.
并将命令行参数的起始位置设置为栈的起始位置.

https://github.com/novelinux/linux-4.x.y/tree/master/fs/exec.c/setup_arg_pages.md

current->mm->start_stack
----------------------------------------

```
    current->mm->start_stack = bprm->p;
```

### Layout

```
|--------------------------------------| 0xffffffff
|                                      |
|--------------------------------------| <- vma->end (STACK_TOP_MAX: 0xc0000000 - 16MB)
|                                      |
|--------------------------------------| <- bprm->p (vma->end - sizeof (void *))
|                                      |
|--------------------------------------| <- vma->start (vma->end - PAGE_SIZE)
```

Program Headers (PT_LOAD)
----------------------------------------

```
    /* Now we do a little grungy work by mmapping the ELF image into
       the correct location in memory. */
    for(i = 0, elf_ppnt = elf_phdata;
        i < loc->elf_ex.e_phnum; i++, elf_ppnt++) {
        int elf_prot = 0, elf_flags;
        unsigned long k, vaddr;
        unsigned long total_size = 0;

        if (elf_ppnt->p_type != PT_LOAD)
            continue;

        if (unlikely (elf_brk > elf_bss)) {
            unsigned long nbyte;

            /* There was a PT_LOAD segment with p_memsz > p_filesz
               before this one. Map anonymous pages, if needed,
               and clear the area.  */
            retval = set_brk(elf_bss + load_bias,
                     elf_brk + load_bias);
            if (retval)
                goto out_free_dentry;
            nbyte = ELF_PAGEOFFSET(elf_bss);
            if (nbyte) {
                nbyte = ELF_MIN_ALIGN - nbyte;
                if (nbyte > elf_brk - elf_bss)
                    nbyte = elf_brk - elf_bss;
                if (clear_user((void __user *)elf_bss +
                            load_bias, nbyte)) {
                    /*
                     * This bss-zeroing can fail if the ELF
                     * file specifies odd protections. So
                     * we don't check the return value
                     */
                }
            }
        }
```

### elf_ppnt

```
        if (elf_ppnt->p_flags & PF_R)
            elf_prot |= PROT_READ;
        if (elf_ppnt->p_flags & PF_W)
            elf_prot |= PROT_WRITE;
        if (elf_ppnt->p_flags & PF_X)
            elf_prot |= PROT_EXEC;
```

### elf_flags

```
        elf_flags = MAP_PRIVATE | MAP_DENYWRITE | MAP_EXECUTABLE;

        vaddr = elf_ppnt->p_vaddr;
        if (loc->elf_ex.e_type == ET_EXEC || load_addr_set) {
            elf_flags |= MAP_FIXED;
        } else if (loc->elf_ex.e_type == ET_DYN) {
            /* Try and get dynamic programs out of the way of the
             * default mmap base, as well as whatever program they
             * might try to exec.  This is because the brk will
             * follow the loader, and is not movable.  */
            load_bias = ELF_ET_DYN_BASE - vaddr;
            if (current->flags & PF_RANDOMIZE)
                load_bias += arch_mmap_rnd();
            load_bias = ELF_PAGESTART(load_bias);
            total_size = total_mapping_size(elf_phdata,
                            loc->elf_ex.e_phnum);
            if (!total_size) {
                retval = -EINVAL;
                goto out_free_dentry;
            }
        }
```

### elf_map

```
        error = elf_map(bprm->file, load_bias + vaddr, elf_ppnt,
                elf_prot, elf_flags, total_size);
        if (BAD_ADDR(error)) {
            retval = IS_ERR((void *)error) ?
                PTR_ERR((void*)error) : -EINVAL;
            goto out_free_dentry;
        }
```

###

```
        if (!load_addr_set) {
            load_addr_set = 1;
            load_addr = (elf_ppnt->p_vaddr - elf_ppnt->p_offset);
            if (loc->elf_ex.e_type == ET_DYN) {
                load_bias += error -
                             ELF_PAGESTART(load_bias + vaddr);
                load_addr += load_bias;
                reloc_func_desc = load_bias;
            }
        }
        k = elf_ppnt->p_vaddr;
        if (k < start_code)
            start_code = k;
        if (start_data < k)
            start_data = k;

        /*
         * Check to see if the section's size will overflow the
         * allowed task size. Note that p_filesz must always be
         * <= p_memsz so it is only necessary to check p_memsz.
         */
        if (BAD_ADDR(k) || elf_ppnt->p_filesz > elf_ppnt->p_memsz ||
            elf_ppnt->p_memsz > TASK_SIZE ||
            TASK_SIZE - elf_ppnt->p_memsz < k) {
            /* set_brk can never work. Avoid overflows. */
            retval = -EINVAL;
            goto out_free_dentry;
        }

        k = elf_ppnt->p_vaddr + elf_ppnt->p_filesz;

        if (k > elf_bss)
            elf_bss = k;
        if ((elf_ppnt->p_flags & PF_X) && end_code < k)
            end_code = k;
        if (end_data < k)
            end_data = k;
        k = elf_ppnt->p_vaddr + elf_ppnt->p_memsz;
        if (k > elf_brk)
            elf_brk = k;
    }
```

----------------------------------------

```
    loc->elf_ex.e_entry += load_bias;
    elf_bss += load_bias;
    elf_brk += load_bias;
    start_code += load_bias;
    end_code += load_bias;
    start_data += load_bias;
    end_data += load_bias;

    /* Calling set_brk effectively mmaps the pages that we need
     * for the bss and break sections.  We must do this before
     * mapping in the interpreter, to make sure it doesn't wind
     * up getting placed where the bss needs to go.
     */
    retval = set_brk(elf_bss, elf_brk);
    if (retval)
        goto out_free_dentry;
    if (likely(elf_bss != elf_brk) && unlikely(padzero(elf_bss))) {
        retval = -EFAULT; /* Nobody gets to see this, but.. */
        goto out_free_dentry;
    }

    if (elf_interpreter) {
        unsigned long interp_map_addr = 0;

        elf_entry = load_elf_interp(&loc->interp_elf_ex,
                        interpreter,
                        &interp_map_addr,
                        load_bias, interp_elf_phdata);
        if (!IS_ERR((void *)elf_entry)) {
            /*
             * load_elf_interp() returns relocation
             * adjustment
             */
            interp_load_addr = elf_entry;
            elf_entry += loc->interp_elf_ex.e_entry;
        }
        if (BAD_ADDR(elf_entry)) {
            retval = IS_ERR((void *)elf_entry) ?
                    (int)elf_entry : -EINVAL;
            goto out_free_dentry;
        }
        reloc_func_desc = interp_load_addr;

        allow_write_access(interpreter);
        fput(interpreter);
        kfree(elf_interpreter);
    } else {
        elf_entry = loc->elf_ex.e_entry;
        if (BAD_ADDR(elf_entry)) {
            retval = -EINVAL;
            goto out_free_dentry;
        }
    }

    kfree(interp_elf_phdata);
    kfree(elf_phdata);

    set_binfmt(&elf_format);

#ifdef ARCH_HAS_SETUP_ADDITIONAL_PAGES
    retval = arch_setup_additional_pages(bprm, !!elf_interpreter);
    if (retval < 0)
        goto out;
#endif /* ARCH_HAS_SETUP_ADDITIONAL_PAGES */

    install_exec_creds(bprm);
    retval = create_elf_tables(bprm, &loc->elf_ex,
              load_addr, interp_load_addr);
    if (retval < 0)
        goto out;
    /* N.B. passed_fileno might not be initialized? */
    current->mm->end_code = end_code;
    current->mm->start_code = start_code;
    current->mm->start_data = start_data;
    current->mm->end_data = end_data;
    current->mm->start_stack = bprm->p;

    if ((current->flags & PF_RANDOMIZE) && (randomize_va_space > 1)) {
        current->mm->brk = current->mm->start_brk =
            arch_randomize_brk(current->mm);
#ifdef compat_brk_randomized
        current->brk_randomized = 1;
#endif
    }

    if (current->personality & MMAP_PAGE_ZERO) {
        /* Why this, you ask???  Well SVr4 maps page 0 as read-only,
           and some applications "depend" upon this behavior.
           Since we do not have the power to recompile these, we
           emulate the SVr4 behavior. Sigh. */
        error = vm_mmap(NULL, 0, PAGE_SIZE, PROT_READ | PROT_EXEC,
                MAP_FIXED | MAP_PRIVATE, 0);
    }

#ifdef ELF_PLAT_INIT
    /*
     * The ABI may specify that certain registers be set up in special
     * ways (on i386 %edx is the address of a DT_FINI function, for
     * example.  In addition, it may also specify (eg, PowerPC64 ELF)
     * that the e_entry field is the address of the function descriptor
     * for the startup routine, rather than the address of the startup
     * routine itself.  This macro performs whatever initialization to
     * the regs structure is required as well as any relocations to the
     * function descriptor entries when executing dynamically links apps.
     */
    ELF_PLAT_INIT(regs, reloc_func_desc);
#endif

    start_thread(regs, elf_entry, bprm->p);
    retval = 0;
out:
    kfree(loc);
out_ret:
    return retval;

    /* error cleanup */
out_free_dentry:
    kfree(interp_elf_phdata);
    allow_write_access(interpreter);
    if (interpreter)
        fput(interpreter);
out_free_interp:
    kfree(elf_interpreter);
out_free_ph:
    kfree(elf_phdata);
    goto out;
}
```

13.映射PT_LOAD段
----------------------------------------

```
    unsigned long load_addr = 0, load_bias = 0;
    ...
    /* Now we do a little grungy work by mmapping the ELF image into
       the correct location in memory. */
    for(i = 0, elf_ppnt = elf_phdata;
        i < loc->elf_ex.e_phnum; i++, elf_ppnt++) {
        int elf_prot = 0, elf_flags;
        unsigned long k, vaddr;

        /* 1.还是从目标映像的程序头表中搜索，这一次是寻找类型为PT_LOAD
         * 的段。在二进制映像中，只有类型为PT_LOAD的部才是需要装入的。
         */
        if (elf_ppnt->p_type != PT_LOAD)
            continue;

        if (unlikely (elf_brk > elf_bss)) {
            unsigned long nbyte;

            /* There was a PT_LOAD segment with p_memsz > p_filesz
               before this one. Map anonymous pages, if needed,
               and clear the area.  */
            retval = set_brk(elf_bss + load_bias,
                     elf_brk + load_bias);
            if (retval)
                goto out_free_dentry;
            nbyte = ELF_PAGEOFFSET(elf_bss);
            if (nbyte) {
                nbyte = ELF_MIN_ALIGN - nbyte;
                if (nbyte > elf_brk - elf_bss)
                    nbyte = elf_brk - elf_bss;
                if (clear_user((void __user *)elf_bss +
                            load_bias, nbyte)) {
                    /*
                     * This bss-zeroing can fail if the ELF
                     * file specifies odd protections. So
                     * we don't check the return value
                     */
                }
            }
        }

        /* 2.设置程序段(PT_LOAD)的权限. */
        if (elf_ppnt->p_flags & PF_R)
            elf_prot |= PROT_READ;
        if (elf_ppnt->p_flags & PF_W)
            elf_prot |= PROT_WRITE;
        if (elf_ppnt->p_flags & PF_X)
            elf_prot |= PROT_EXEC;
        /* MAP_PRIVATE创建一个与数据源分离的私有映射，对映射区域的
         * 写入操作不影响文件中的数据.
         */
        elf_flags = MAP_PRIVATE | MAP_DENYWRITE | MAP_EXECUTABLE;

        /* 3.找到一个PT_LOAD片以后，先要确定其装入地址。程序头
         * 数据结构中的p_vaddr提供了映像在连接时确定的装入地址vaddr。
         */
        vaddr = elf_ppnt->p_vaddr;
        /* 4.根据程序二进制头的type设置程序段的权限和装入地址. */
        /* A.如果映像的类型为ET_EXEC那么装入地址就是固定的
         * MAP_FIXED - 指定除了给定的地址之外，不能将其它地址用于映射.
         * 如果没有设置该标志，内核可以在受阻时随意改变目标地址.
         */
        if (loc->elf_ex.e_type == ET_EXEC || load_addr_set) {
            elf_flags |= MAP_FIXED;
        /* B.而若类型为ET_DYN(即共享库)，那么即使装入地址固定也要
         * 加上一个偏移量.
         */
        } else if (loc->elf_ex.e_type == ET_DYN) {
            /* Try and get dynamic programs out of the way of the
             * default mmap base, as well as whatever program they
             * might try to exec.  This is because the brk will
             * follow the loader, and is not movable.  */
#ifdef CONFIG_ARCH_BINFMT_ELF_RANDOMIZE_PIE
            /* Memory randomization might have been switched off
             * in runtime via sysctl or explicit setting of
             * personality flags.
             * If that is the case, retain the original non-zero
             * load_bias value in order to establish proper
             * non-randomized mappings.
             */
             /* #define ELF_PAGESTART(_v) \
              *     ((_v) & ~(unsigned long)(ELF_MIN_ALIGN-1))
              * 该宏负责将装入地址按照ELF_MIN_ALIGN对齐，通常
              * ELF_MIN_ALIGN的大小为PAGE_SIZE, 也就是按页对齐.
              * ELF_ET_DYN_BASE定义如下所示:
              * #define ELF_ET_DYN_BASE (2 * TASK_SIZE / 3)
              * 装入地址即为：ELF_ET_DYN_BASE - vaddr按页对齐的地址.
              */
            if (current->flags & PF_RANDOMIZE)
                load_bias = 0;
            else
                load_bias = ELF_PAGESTART(ELF_ET_DYN_BASE - vaddr);
#else
            load_bias = ELF_PAGESTART(ELF_ET_DYN_BASE - vaddr);
#endif
        }

        /* 确定了装入地址以后，就通过elf_map()建立进程虚拟地址空间与
         * 目标映像文件中某个连续区间之间的映射。返回值是实际映射的
         * 起始地址.
         */
        error = elf_map(bprm->file, load_bias + vaddr, elf_ppnt,
                elf_prot, elf_flags, 0);
        if (BAD_ADDR(error)) {
            retval = IS_ERR((void *)error) ?
                PTR_ERR((void*)error) : -EINVAL;
            goto out_free_dentry;
        }

        /* load_addr_set已经被设置成1, 那么装入地址load_bias就是固定的
         * load_addr_set默认是0, 那么针对DYN类型的elf格式文件其load_addr
         * 和load_bias的值一般是等同于error(即实际映射的起始地址).
         * 从elf_map得知elf这个DYN类型文件该值为0xb6f21000
         */
        if (!load_addr_set) {
            load_addr_set = 1;
            load_addr = (elf_ppnt->p_vaddr - elf_ppnt->p_offset);
            if (loc->elf_ex.e_type == ET_DYN) {
                load_bias += error -
                             ELF_PAGESTART(load_bias + vaddr);
                load_addr += load_bias;
                reloc_func_desc = load_bias;
            }
        }

        /* 下面的一段代码用于计算代码区和数据区的开始位置:
         * 由于代码区在进程空间的最前面，如果当前映射的这一段的开始位置
         * 还位于当前的代码区之前，那么代码区的开始位置应该还要向前移，
         * 至少移到这一段的位置上。
         * 而如果当前映射的这一段的开始位置还位于当前的数据区之后，
         * 那么数据区的开始位置还应该向后移，至少移到这一段的位置上。
         * 这是因为数据区在可装载的段的最后，不应该有哪个段的位置比较数据区还靠后。
         */
        k = elf_ppnt->p_vaddr;
        if (k < start_code)
            start_code = k;
        if (start_data < k)
            start_data = k;

        /*
         * Check to see if the section's size will overflow the
         * allowed task size. Note that p_filesz must always be
         * <= p_memsz so it is only necessary to check p_memsz.
         */
        if (BAD_ADDR(k) || elf_ppnt->p_filesz > elf_ppnt->p_memsz ||
            elf_ppnt->p_memsz > TASK_SIZE ||
            TASK_SIZE - elf_ppnt->p_memsz < k) {
            /* set_brk can never work. Avoid overflows. */
            retval = -EINVAL;
            goto out_free_dentry;
        }
        /* 接下来的代码是用于计算几个区的结束位置: */
        k = elf_ppnt->p_vaddr + elf_ppnt->p_filesz;

        /* elf_bss变量记录的是BSS区的开始位置。BSS区排在所有可加载段的后面，
         * 即它的开始处也就是最后一个可加载段的结尾处。所以总是把当前加载段
         * 的结尾与它相比，如果当前加载段的结尾比较靠后的话，则还需要把BSS区往后推。
         */
        if (k > elf_bss)
            elf_bss = k;
        if ((elf_ppnt->p_flags & PF_X) && end_code < k)
            end_code = k;
        if (end_data < k)
            end_data = k;
        /* elf_brk变量记录的是堆(heap)的上边界，现在进程还没有运行起来，没有从堆上面申请内存，
         * 所以堆的大小是0，堆的上边界与下边界重合，而堆的位置还在BSS之后，即它的开始位置应该是
         * BSS区的结构位置。一般情况下，一个程序头的p_memsz与p_filesz如果不一样大小的话，
         * 其差值应是未初始化全局变量的大小，这段空间应归入BSS区。上面代码中两个k值的计算
         * 正是考虑到这一点，所以第二次k值(BRK)的计算是把BSS区大小也计算在内的。
         */
        k = elf_ppnt->p_vaddr + elf_ppnt->p_memsz;
        if (k > elf_brk)
            elf_brk = k;
    }
    ...
```

### elf_map

elf_map的具体实现如下所示：

https://github.com/novelinux/linux-4.x.y/tree/master/fs/binfmt_elf_c/elf_map.md

### 计算进程空间各段起始地址和结束地址

针对名称elf(DYN)这个文件我们计算出的各段值如下所示:

在加载完PT_LOAD1段时各值结果如下所示:

```
start_code=0x0
end_code=0x494
start_data=0x0
end_data=0x494
elf_bss=0x494
elf_brk=0x494
```

在加载完PT_LOAD2段时各值结果如下所示:

```
start_code=0x0
end_code=0x494
start_data=0x1ec0
end_data=0x2000
elf_bss=0x2000
elf_brk=0x2004
```

14.计算进程各段地址
----------------------------------------

进程虚拟内存空间布局如下所示:

https://github.com/novelinux/linux-4.x.y/tree/master/mm/task_vm_layout.md

```
    ...
    loc->elf_ex.e_entry += load_bias;
    elf_bss += load_bias;
    elf_brk += load_bias;
    start_code += load_bias;
    end_code += load_bias;
    start_data += load_bias;
    end_data += load_bias;
    ...
```

通过如上计算得到的各段值如下所示:

```
entry=b6f84360
start_code=b6f84000
end_code=b6f84494
start_data=b6f85ec0
end_data=b6f86000
elf_bss=b6f86000
elf_brk=b6f86004
```

对应完整的maps如下所示

https://github.com/novelinux/linux-4.x.y/tree/master/fs/binfmt_elf_c/elf.maps

接下来调用set_brk来设置bss段和brk段信息,如下所示:

15.set_brk设置brk段
----------------------------------------

```
    ...
    /* Calling set_brk effectively mmaps the pages that we need
     * for the bss and break sections.  We must do this before
     * mapping in the interpreter, to make sure it doesn't wind
     * up getting placed where the bss needs to go.
     */
    retval = set_brk(elf_bss, elf_brk);
    if (retval)
        goto out_free_dentry;
    if (likely(elf_bss != elf_brk) && unlikely(padzero(elf_bss))) {
        retval = -EFAULT; /* Nobody gets to see this, but.. */
        goto out_free_dentry;
    }
    ...
```

set_brk函数用来设置当前进程brk空间区域，具体实现如下所示:

https://github.com/novelinux/linux-4.x.y/tree/master/fs/binfmt_elf_c/set_brk.md

经过set_brk设置之后，当前进程的brk段起始地址和结束地址如下所示:

```
start_brk=0xb6f87000
end_brk=0xb6f87000
```

16.load_elf_interp
----------------------------------------

elf_interpreter指向解释器(连接器)名称,如果有解释器，则调用load_elf_interp
函数装载解释器文件.并把将来进入用户空间时的入口地址设置成load_elf_interp()的返回值，
那显然是解释器的程序入口。而若不装入解释器，那么这个地址就是目标映像本身的程序入口。

```
    ...
    if (elf_interpreter) {
        unsigned long interp_map_addr = 0;

        /* 返回解释器(linker)映射的首地址. */
        elf_entry = load_elf_interp(&loc->interp_elf_ex,
                        interpreter,
                        &interp_map_addr,
                        load_bias, interp_elf_phdata);
        if (!IS_ERR((void *)elf_entry)) {
            /*
             * load_elf_interp() returns relocation
             * adjustment
             */
            interp_load_addr = elf_entry;
            /* 接下来将映射首地址再加上对应解释器的入口偏移量即可. */
            elf_entry += loc->interp_elf_ex.e_entry;
        }
        if (BAD_ADDR(elf_entry)) {
            retval = IS_ERR((void *)elf_entry) ?
                    (int)elf_entry : -EINVAL;
            goto out_free_dentry;
        }
        reloc_func_desc = interp_load_addr;

        allow_write_access(interpreter);
        fput(interpreter);
        kfree(elf_interpreter);
    } else {
        elf_entry = loc->elf_ex.e_entry;
        if (BAD_ADDR(elf_entry)) {
            retval = -EINVAL;
            goto out_free_dentry;
        }
    }

    kfree(interp_elf_phdata);
    kfree(elf_phdata);
    ...
```

load_elf_interp具体实现如下所示:

https://github.com/novelinux/linux-4.x.y/tree/master/fs/binfmt_elf_c/load_elf_interp.md

针对本例来说，linker作为解释器，其映射首地址为b6f74000(elf_entry),也就是load_elf_interp的返回值.

17.set_binfmt
----------------------------------------

```
    ...
    set_binfmt(&elf_format);
    ...
```

elf_format定义如下所示:

path: fs/binfmt_elf.c
```
static struct linux_binfmt elf_format = {
    .module       = THIS_MODULE,
    .load_binary  = load_elf_binary,
    .load_shlib   = load_elf_library,
    .core_dump    = elf_core_dump,
    .min_coredump = ELF_EXEC_PAGESIZE,
};
...
```

接下来调用set_binfmt函数将对应的elf格式文件的处理接口函数包存到描述当前进程空间的
数据结构mm_struct实例的成员变量binfmt中去.具体实现如下所示:

https://github.com/novelinux/linux-4.x.y/tree/master/fs/exec_c/set_binfmt.md

18.install_exec_creds
----------------------------------------

```
    ...
#ifdef ARCH_HAS_SETUP_ADDITIONAL_PAGES
    retval = arch_setup_additional_pages(bprm, !!elf_interpreter);
    if (retval < 0)
        goto out;
#endif /* ARCH_HAS_SETUP_ADDITIONAL_PAGES */

    install_exec_creds(bprm);
    ...
```

install_exec_creds为新的可执行二进制文件配置credentials.具体实现如下所示:

https://github.com/novelinux/linux-4.x.y/tree/master/fs/exec_c/install_exec_creds.md

19.create_elf_tables
----------------------------------------

```
    ...
    retval = create_elf_tables(bprm, &loc->elf_ex,
              load_addr, interp_load_addr);
    if (retval < 0)
        goto out;
    ...
```

调用create_elf_tables，它将argc、argv等，还有一些辅助向量(Auxiliary Vector)等信息复制到用户栈空间.
具体实现如下所示:

https://github.com/novelinux/linux-4.x.y/tree/master/fs/binfmt_elf_c/create_elf_tables.md

针对本实例，设置完成后用户栈顶指针(bprm->p)指向的地址为0xbeb36850.

20.设置进程code, data, stack段信息
----------------------------------------

接下来设置描述当前进程虚拟地址空间的mm_struct实例中各段的起始和结束地址.

```
    ...
    /* N.B. passed_fileno might not be initialized? */
    current->mm->end_code = end_code;
    current->mm->start_code = start_code;
    current->mm->start_data = start_data;
    current->mm->end_data = end_data;
    current->mm->start_stack = bprm->p;

#ifdef arch_randomize_brk
    if ((current->flags & PF_RANDOMIZE) && (randomize_va_space > 1)) {
        current->mm->brk = current->mm->start_brk =
            arch_randomize_brk(current->mm);
#ifdef CONFIG_COMPAT_BRK
        current->brk_randomized = 1;
#endif
    }
#endif

    if (current->personality & MMAP_PAGE_ZERO) {
        /* Why this, you ask???  Well SVr4 maps page 0 as read-only,
           and some applications "depend" upon this behavior.
           Since we do not have the power to recompile these, we
           emulate the SVr4 behavior. Sigh. */
        error = vm_mmap(NULL, 0, PAGE_SIZE, PROT_READ | PROT_EXEC,
                MAP_FIXED | MAP_PRIVATE, 0);
    }
    ...
```

21.start_thread
----------------------------------------

elf_entry当前指向了解释器(linker)的入口地址.接下来调用start_thread加载执行新进程程序.

```
    ...
#ifdef ELF_PLAT_INIT
    /*
     * The ABI may specify that certain registers be set up in special
     * ways (on i386 %edx is the address of a DT_FINI function, for
     * example.  In addition, it may also specify (eg, PowerPC64 ELF)
     * that the e_entry field is the address of the function descriptor
     * for the startup routine, rather than the address of the startup
     * routine itself.  This macro performs whatever initialization to
     * the regs structure is required as well as any relocations to the
     * function descriptor entries when executing dynamically links apps.
     */
    ELF_PLAT_INIT(regs, reloc_func_desc);
#endif

    start_thread(regs, elf_entry, bprm->p);
    retval = 0;
    ...
```

start_thread跟体系结构相关，具体实现如下所示:

### arm

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/include/asm/processor_h/start_thread.md
