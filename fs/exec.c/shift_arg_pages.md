shift_arg_pages
========================================

path: fs/exec.c
```
#ifdef CONFIG_MMU

/*
 * During bprm_mm_init(), we create a temporary stack at STACK_TOP_MAX.  Once
 * the binfmt code determines where the new stack should reside, we shift it to
 * its final location.  The process proceeds as follows:
 *
 * 1) Use shift to calculate the new vma endpoints.
 * 2) Extend vma to cover both the old and new ranges.  This ensures the
 *    arguments passed to subsequent functions are consistent.
 * 3) Move vma's page tables to the new range.
 * 4) Free up any cleared pgd range.
 * 5) Shrink the vma to cover only the new range.
 */
static int shift_arg_pages(struct vm_area_struct *vma, unsigned long shift)
{
    struct mm_struct *mm = vma->vm_mm;
    unsigned long old_start = vma->vm_start;
    unsigned long old_end = vma->vm_end;
    unsigned long length = old_end - old_start;
    unsigned long new_start = old_start - shift;
    unsigned long new_end = old_end - shift;
    struct mmu_gather tlb;

    BUG_ON(new_start > new_end);

    /*
     * ensure there are no vmas between where we want to go
     * and where we are
     */
    if (vma != find_vma(mm, new_start))
        return -EFAULT;

    /*
     * cover the whole range: [new_start, old_end)
     */
    if (vma_adjust(vma, new_start, old_end, vma->vm_pgoff, NULL))
        return -ENOMEM;

    /*
     * move the page tables downwards, on failure we rely on
     * process cleanup to remove whatever mess we made.
     */
    if (length != move_page_tables(vma, old_start,
                       vma, new_start, length, false))
        return -ENOMEM;

    lru_add_drain();
    tlb_gather_mmu(&tlb, mm, old_start, old_end);
    if (new_end > old_start) {
        /*
         * when the old and new regions overlap clear from new_end.
         */
        free_pgd_range(&tlb, new_end, old_end, new_end,
            vma->vm_next ? vma->vm_next->vm_start : USER_PGTABLES_CEILING);
    } else {
        /*
         * otherwise, clean from old_start; this is done to not touch
         * the address space in [new_end, old_start) some architectures
         * have constraints on va-space that make this illegal (IA64) -
         * for the others its just a little faster.
         */
        free_pgd_range(&tlb, old_start, old_end, new_end,
            vma->vm_next ? vma->vm_next->vm_start : USER_PGTABLES_CEILING);
    }
    tlb_finish_mmu(&tlb, old_start, old_end);

    /*
     * Shrink the vma to just the new range.  Always succeeds.
     */
    vma_adjust(vma, new_start, new_end, vma->vm_pgoff, NULL);

    return 0;
}
```
