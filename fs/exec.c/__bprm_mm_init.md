__bprm_mm_init
========================================

__bprm_mm_init主要在新进程的虚拟地址空间中分配一块新的区域使用vm_area_struct来描述

Arguments
----------------------------------------

path: fs/exec.c
```
static int __bprm_mm_init(struct linux_binprm *bprm)
{
    int err;
    struct vm_area_struct *vma = NULL;
    struct mm_struct *mm = bprm->mm;

    // 创建一个vm_area_struct实例保存到bprm->vma用来描述虚拟地址空间中一块区域
    bprm->vma = vma = kmem_cache_zalloc(vm_area_cachep, GFP_KERNEL);
    if (!vma)
        return -ENOMEM;

    down_write(&mm->mmap_sem);
```

Initialize vma
----------------------------------------

初始化新建区域.

```
    // 将该区域vm_mm反向指向mm(描述进程的地址空间)
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
```

### STACK_TOP_MAX

#### ARM

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/include/asm/processor.h/STACK_TOP_MAX.md

### vma Layout

```
|--------------------------------------| 0xffffffff
|                                      |
|--------------------------------------| <- vma->end (STACK_TOP_MAX: 0xc0000000 - 16MB)
|                                      |
|--------------------------------------| <- bprm->p (vma->end - sizeof (void *))
|                                      |
|--------------------------------------| <- vma->start (vma->end - PAGE_SIZE)
```

insert_vm_struct
----------------------------------------

```
    err = insert_vm_struct(mm, vma);
    if (err)
        goto err;

    // 设置用户态堆栈页数和进程虚拟地址空间的页数为1页.
    mm->stack_vm = mm->total_vm = 1;
    // 与体系结构相关的进程虚拟地址空间初始化.
    arch_bprm_mm_init(mm, vma);
    up_write(&mm->mmap_sem);
    // 设置当前二进制文件描述符的p位置为距离新建区域结束地址sizeof (void*)处. */
    bprm->p = vma->vm_end - sizeof(void *);
    return 0;
```

insert_vm_struct用于将新分配的区域插入到进程虚拟地址空间的管理数据结构mm_struct中.

https://github.com/novelinux/linux-4.x.y/tree/master/mm/mmap.c/insert_vm_struct.md

err
----------------------------------------

```
err:
    up_write(&mm->mmap_sem);
    bprm->vma = NULL;
    kmem_cache_free(vm_area_cachep, vma);
    return err;
}
```
