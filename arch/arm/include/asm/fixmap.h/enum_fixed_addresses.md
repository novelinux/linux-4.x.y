fixed_addresses
========================================

path: arch/arm/include/asm/fixmap.h
```
enum fixed_addresses {
     FIX_EARLYCON_MEM_BASE,
     __end_of_permanent_fixed_addresses,

     FIX_KMAP_BEGIN = __end_of_permanent_fixed_addresses,
     FIX_KMAP_END = FIX_KMAP_BEGIN + (KM_TYPE_NR * NR_CPUS) - 1,

     /* Support writing RO kernel text via kprobes, jump labels, etc. */
     FIX_TEXT_POKE0,
     FIX_TEXT_POKE1,

     __end_of_fixed_addresses
};
```