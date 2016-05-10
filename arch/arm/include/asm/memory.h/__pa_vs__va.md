__pa vs __va
========================================

内核定义了两个宏来进行物理地址和虚拟地址之间的转换。注意这里的转换只有在直接映射的情况下才有效，
也即在使用段页表的情况下才有效，它们被线性映射，物理地址和虚拟地址间的偏移保持一致，通过直接的
加减进行转换。虚拟地址减去虚拟地址的偏移地址PAGE_OFFSET(0xc0000000)然后加上物理地址的偏移地址
(0x80200000)即可得到对应的的物理地址，反向亦然。

path: arch/arm/include/asm/memory.h
```
/*
 * Drivers should NOT use these either.
 */
#define __pa(x)            __virt_to_phys((unsigned long)(x))
#define __va(x)            ((void *)__phys_to_virt((phys_addr_t)(x)))
```

__virt_to_phys
----------------------------------------

static inline phys_addr_t __virt_to_phys(unsigned long x)
{
    return (phys_addr_t)x - PAGE_OFFSET + PHYS_OFFSET;
}

__phys_to_virt
----------------------------------------

static inline unsigned long __phys_to_virt(phys_addr_t x)
{
    return x - PHYS_OFFSET + PAGE_OFFSET;
}

PAGE_OFFSET
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/include/asm/memory.h/PAGE_OFFSET.md

PHYS_OFFSET
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/include/asm/memory.h/PHYS_OFFSET.md
