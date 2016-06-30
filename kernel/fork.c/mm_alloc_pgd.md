mm_alloc_pgd
========================================

path: kernel/fork.c
```
static inline int mm_alloc_pgd(struct mm_struct *mm)
{
    mm->pgd = pgd_alloc(mm);
    if (unlikely(!mm->pgd))
        return -ENOMEM;
    return 0;
}
```

pgd_alloc
----------------------------------------

### ARM

https://github.com/novelinux/linux-4.x.y/blob/master/arch/arm/mm/pgd.c/pgd_alloc.md
