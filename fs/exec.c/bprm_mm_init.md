bprm_mm_init
========================================

Arguments
----------------------------------------

path: fs/exec.c
```
/*
 * Create a new mm_struct and populate it with a temporary stack
 * vm_area_struct.  We don't have enough context at this point to set the stack
 * flags, permissions, and offset, so we use temporary values.  We'll update
 * them later in setup_arg_pages().
 */
static int bprm_mm_init(struct linux_binprm *bprm)
{
    int err;
    struct mm_struct *mm = NULL;
```

mm_alloc
----------------------------------------

```
    bprm->mm = mm = mm_alloc();
    err = -ENOMEM;
    if (!mm)
        goto err;
```

创建一个mm_struct实例管理新进程的进程地址空间.

__bprm_mm_init
----------------------------------------

```
    err = __bprm_mm_init(bprm);
    if (err)
        goto err;

    return 0;
```

err
----------------------------------------

```
err:
    if (mm) {
        bprm->mm = NULL;
        mmdrop(mm);
    }

    return err;
}
```

```
    vma->vm_mm = mm;

    /*
     * Place the stack at the largest stack address the architecture
     * supports. Later, we'll move this to an appropriate place. We don't
     * use STACK_TOP because that can depend on attributes which aren't
     * configured yet.
     */

    BUILD_BUG_ON(VM_STACK_FLAGS & VM_STACK_INCOMPLETE_SETUP);
    // 设置该区域的结束地址为STACK_TOP_MAX
    vma->vm_end = STACK_TOP_MAX;
    // 设置该区域的起始地址为结束地址减去一页大小，说明该区域大小为1页
    vma->vm_start = vma->vm_end - PAGE_SIZE;
    // 设置区域的标志
    vma->vm_flags = VM_SOFTDIRTY | VM_STACK_FLAGS | VM_STACK_INCOMPLETE_SETUP;
    // 设置区域的权限
    vma->vm_page_prot = vm_get_page_prot(vma->vm_flags);
    // 初始化匿名链
    INIT_LIST_HEAD(&vma->anon_vma_chain);

    /* 4.调用insert_vm_struct函数插入新区域到mm_struct结构中 */
    err = insert_vm_struct(mm, vma);
    if (err)
        goto err;

    /* 5.设置用户态堆栈页数和进程虚拟地址空间的页数为1页. */
    mm->stack_vm = mm->total_vm = 1;
    /* 6.与体系结构相关的进程虚拟地址空间初始化. */
    arch_bprm_mm_init(mm, vma);
    up_write(&mm->mmap_sem);
    /* 7.设置当前二进制文件描述符的p位置为距离新建区域结束地址sizeof (void*)处. */
    bprm->p = vma->vm_end - sizeof(void *);
    return 0;
err:
    up_write(&mm->mmap_sem);
    bprm->vma = NULL;
    kmem_cache_free(vm_area_cachep, vma);
    return err;
}
```

STACK_TOP_MAX
----------------------------------------

STACK_TOP_MAX定义如下所示：

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/include/asm/memory_h/memory.md

进程虚拟地址空间布局:
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/task_vm_layout.md

insert_vm_struct
----------------------------------------

insert_vm_struct用于将新分配的区域插入到进程虚拟地址空间的管理数据结构mm_struct中，
具体实现如下所示:

https://github.com/novelinux/linux-4.x.y/tree/master/mm/mmap_c/insert_vm_struct.md
