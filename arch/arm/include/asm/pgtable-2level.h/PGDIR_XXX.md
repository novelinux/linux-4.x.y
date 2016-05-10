PGDIR_SIZE
========================================

path: arch/arm/include/asm/pgtable-2level.h
```
#define PGDIR_SHIFT        21
...
#define PGDIR_SIZE        (1UL << PGDIR_SHIFT)
#define PGDIR_MASK        (~(PGDIR_SIZE-1))
```