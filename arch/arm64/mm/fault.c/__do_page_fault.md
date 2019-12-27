## __do_page_fault

```
static vm_fault_t __do_page_fault(struct mm_struct *mm, unsigned long addr,
			   unsigned int mm_flags, unsigned long vm_flags)
{
	struct vm_area_struct *vma = find_vma(mm, addr);

	if (unlikely(!vma))
		return VM_FAULT_BADMAP;

	/*
	 * Ok, we have a good vm_area for this memory access, so we can handle
	 * it.
	 */
	if (unlikely(vma->vm_start > addr)) {
		if (!(vma->vm_flags & VM_GROWSDOWN))
			return VM_FAULT_BADMAP;
		if (expand_stack(vma, addr))
			return VM_FAULT_BADMAP;
	}

	/*
	 * Check that the permissions on the VMA allow for the fault which
	 * occurred.
	 */
	if (!(vma->vm_flags & vm_flags))
		return VM_FAULT_BADACCESS;
	return handle_mm_fault(vma, addr & PAGE_MASK, mm_flags);
}
```

[handle_mm_fault](../../../../mm/memory.c/handle_mm_fault.md)