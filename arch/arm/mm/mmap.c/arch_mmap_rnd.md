arch_mmap_rnd
========================================

path: arch/arm/mm/mmap.c
```
unsigned long arch_mmap_rnd(void)
{
    unsigned long rnd;

    rnd = get_random_long() & ((1UL << mmap_rnd_bits) - 1);

    return rnd << PAGE_SHIFT;
}
```