vm_operations_struct
========================================

open, close
----------------------------------------

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
```

在创建和删除区域时，分别调用open和close. 这两个接口通常不使用，设置为NULL指针.

mremap
----------------------------------------

```
    int (*mremap)(struct vm_area_struct * area);
```

fault
----------------------------------------

```
    int (*fault)(struct vm_area_struct *vma, struct vm_fault *vmf);
```

这是一个非常重要的函数，如果地址空间中的某个虚拟内存页没有映射物理页帧，则自动触发
的缺页异常处理程序会调用该函数，将对应的数据读取到一个映射在用户地址空间的物理页中.

pmd_fault
----------------------------------------

```
    int (*pmd_fault)(struct vm_area_struct *, unsigned long address,
                        pmd_t *, unsigned int flags);
```

map_pages
----------------------------------------

```
    void (*map_pages)(struct vm_area_struct *vma, struct vm_fault *vmf);

    /* notification that a previously read-only page is about to become
     * writable, if an error is returned it will cause a SIGBUS */
    int (*page_mkwrite)(struct vm_area_struct *vma, struct vm_fault *vmf);

    /* same as page_mkwrite when using VM_PFNMAP|VM_MIXEDMAP */
    int (*pfn_mkwrite)(struct vm_area_struct *vma, struct vm_fault *vmf);

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
    /*
     * Called by vm_normal_page() for special PTEs to find the
     * page for @addr.  This is useful if the default behavior
     * (using pte_page()) would not find the correct page.
     */
    struct page *(*find_special_page)(struct vm_area_struct *vma,
                      unsigned long addr);
};
```
