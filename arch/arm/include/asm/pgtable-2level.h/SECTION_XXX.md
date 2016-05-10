SECTION
========================================

path: arch/arm/include/asm/pgtable-2level.h
```
/*
 * section address mask and size definitions.
 */
#define SECTION_SHIFT           20
#define SECTION_SIZE            (1UL << SECTION_SHIFT)
#define SECTION_MASK            (~(SECTION_SIZE-1))
```