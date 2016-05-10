vm_operations_struct
========================================

path: include/linux/mm.h
```
/*
 * These are the virtual MM functions - opening of an area, closing and
 * unmapping it (needed to keep files on disk up-to-date etc), pointer
 * to the functions called when a no-page or a wp-page exception occurs.
 */
struct vm_operations_struct {
    void (*open)(struct vm_area_struct * area);
    void (*close)(struct vm_area_struct * area);
    int (*fault)(struct vm_area_struct *vma, struct vm_fault *vmf);
    void (*map_pages)(struct vm_area_struct *vma, struct vm_fault *vmf);

    /* notification that a previously read-only page is about to become
     * writable, if an error is returned it will cause a SIGBUS */
    int (*page_mkwrite)(struct vm_area_struct *vma, struct vm_fault *vmf);

    /* called by access_process_vm when get_user_pages() fails, typically
     * for use by special VMAs that can switch between memory and hardware
     */
    int (*access)(struct vm_area_struct *vma, unsigned long addr,
              void *buf, int len, int write);

    /* Called by the /proc/PID/maps code to ask the vma whether it
     * has a special name.  Returning non-NULL will also cause this
     * vma to be dumped unconditionally. */
    const char *(*name)(struct vm_area_struct *vma);

#ifdef CONFIG_NUMA
    /*
     * set_policy() op must add a reference to any non-NULL @new mempolicy
     * to hold the policy upon return.  Caller should pass NULL @new to
     * remove a policy and fall back to surrounding context--i.e. do not
     * install a MPOL_DEFAULT policy, nor the task or system default
     * mempolicy.
     */
    int (*set_policy)(struct vm_area_struct *vma, struct mempolicy *new);

    /*
     * get_policy() op must add reference [mpol_get()] to any policy at
     * (vma,addr) marked as MPOL_SHARED.  The shared policy infrastructure
     * in mm/mempolicy.c will do this automatically.
     * get_policy() must NOT add a ref if the policy at (vma,addr) is not
     * marked as MPOL_SHARED. vma policies are protected by the mmap_sem.
     * If no [shared/vma] mempolicy exists at the addr, get_policy() op
     * must return NULL--i.e., do not "fallback" to task or system default
     * policy.
     */
    struct mempolicy *(*get_policy)(struct vm_area_struct *vma,
                    unsigned long addr);
#endif
    /* called by sys_remap_file_pages() to populate non-linear mapping */
    int (*remap_pages)(struct vm_area_struct *vma, unsigned long addr,
               unsigned long size, pgoff_t pgoff);
};
```

open and close
----------------------------------------

在创建和删除区域时，分别调用open和close. 这两个接口通常不使用，设置为NULL指针.

fault
----------------------------------------

这是一个非常重要的函数，如果地址空间中的某个虚拟内存页没有映射物理页帧，则自动触发
的缺页异常处理程序会调用该函数，将对应的数据读取到一个映射在用户地址空间的物理页中.
