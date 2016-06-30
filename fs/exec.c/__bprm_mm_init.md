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
    vma->vm_end = STACK_TOP_MAX;
    vma->vm_start = vma->vm_end - PAGE_SIZE;
    vma->vm_flags = VM_SOFTDIRTY | VM_STACK_FLAGS | VM_STACK_INCOMPLETE_SETUP;
    vma->vm_page_prot = vm_get_page_prot(vma->vm_flags);
    INIT_LIST_HEAD(&vma->anon_vma_chain);

    err = insert_vm_struct(mm, vma);
    if (err)
        goto err;

    mm->stack_vm = mm->total_vm = 1;
    arch_bprm_mm_init(mm, vma);
    up_write(&mm->mmap_sem);
    bprm->p = vma->vm_end - sizeof(void *);
    return 0;
err:
    up_write(&mm->mmap_sem);
    bprm->vma = NULL;
    kmem_cache_free(vm_area_cachep, vma);
    return err;
}
```
