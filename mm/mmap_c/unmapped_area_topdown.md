unmapped_area_topdown
========================================

path: mm/mmap.c
```
unsigned long unmapped_area_topdown(struct vm_unmapped_area_info *info)
{
    struct mm_struct *mm = current->mm;
    struct vm_area_struct *vma;
    unsigned long length, low_limit, high_limit, gap_start, gap_end;

    /* Adjust search length to account for worst case alignment overhead */
    length = info->length + info->align_mask;
    if (length < info->length)
        return -ENOMEM;

    /*
     * Adjust search limits by the desired length.
     * See implementation comment at top of unmapped_area().
     */
    gap_end = info->high_limit;
    if (gap_end < length)
        return -ENOMEM;
    high_limit = gap_end - length;

    if (info->low_limit > high_limit)
        return -ENOMEM;
    low_limit = info->low_limit + length;

    /* Check highest gap, which does not precede any rbtree node */
    gap_start = mm->highest_vm_end;
    if (gap_start <= high_limit)
        goto found_highest;

    /* Check if rbtree root looks promising */
    if (RB_EMPTY_ROOT(&mm->mm_rb))
        return -ENOMEM;
    vma = rb_entry(mm->mm_rb.rb_node, struct vm_area_struct, vm_rb);
    if (vma->rb_subtree_gap < length)
        return -ENOMEM;

    while (true) {
        /* Visit right subtree if it looks promising */
        gap_start = vma->vm_prev ? vma->vm_prev->vm_end : 0;
        if (gap_start <= high_limit && vma->vm_rb.rb_right) {
            struct vm_area_struct *right =
                rb_entry(vma->vm_rb.rb_right,
                     struct vm_area_struct, vm_rb);
            if (right->rb_subtree_gap >= length) {
                vma = right;
                continue;
            }
        }

check_current:
        /* Check if current node has a suitable gap */
        gap_end = vma->vm_start;
        if (gap_end < low_limit)
            return -ENOMEM;
        if (gap_start <= high_limit && gap_end - gap_start >= length)
            goto found;

        /* Visit left subtree if it looks promising */
        if (vma->vm_rb.rb_left) {
            struct vm_area_struct *left =
                rb_entry(vma->vm_rb.rb_left,
                     struct vm_area_struct, vm_rb);
            if (left->rb_subtree_gap >= length) {
                vma = left;
                continue;
            }
        }

        /* Go back up the rbtree to find next candidate node */
        while (true) {
            struct rb_node *prev = &vma->vm_rb;
            if (!rb_parent(prev))
                return -ENOMEM;
            vma = rb_entry(rb_parent(prev),
                       struct vm_area_struct, vm_rb);
            if (prev == vma->vm_rb.rb_right) {
                gap_start = vma->vm_prev ?
                    vma->vm_prev->vm_end : 0;
                goto check_current;
            }
        }
    }

found:
    /* We found a suitable gap. Clip it with the original high_limit. */
    if (gap_end > info->high_limit)
        gap_end = info->high_limit;

found_highest:
    /* Compute highest gap address at the desired alignment */
    gap_end -= info->length;
    gap_end -= (gap_end - info->align_offset) & info->align_mask;

    VM_BUG_ON(gap_end < info->low_limit);
    VM_BUG_ON(gap_end < gap_start);
    return gap_end;
}
```