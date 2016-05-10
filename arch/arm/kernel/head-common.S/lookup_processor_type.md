lookup_processor_type
========================================

path: arch/arm/kernel/head-common.S
```
/*
 * This provides a C-API version of __lookup_processor_type
 */
ENTRY(lookup_processor_type)
    stmfd    sp!, {r4 - r6, r9, lr}
    mov      r9, r0
    bl       __lookup_processor_type
    mov      r0, r5
    ldmfd    sp!, {r4 - r6, r9, pc}
ENDPROC(lookup_processor_type)
```