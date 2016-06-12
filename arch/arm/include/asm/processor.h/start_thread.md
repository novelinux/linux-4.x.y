start_thread
=======================================

path: arch/arm/include/asm/processor.h
```
#define start_thread(regs,pc,sp)                    \
({                                                  \
    memset(regs->uregs, 0, sizeof(regs->uregs));    \
    if (current->personality & ADDR_LIMIT_32BIT)    \
        regs->ARM_cpsr = USR_MODE;                  \
    else                                            \
        regs->ARM_cpsr = USR26_MODE;                \
    if (elf_hwcap & HWCAP_THUMB && pc & 1)          \
        regs->ARM_cpsr |= PSR_T_BIT;                \
    regs->ARM_cpsr |= PSR_ENDSTATE;                 \
    regs->ARM_pc = pc & ~1;        /* pc */         \
    regs->ARM_sp = sp;        /* sp */              \
    nommu_start_thread(regs);                       \
})
```