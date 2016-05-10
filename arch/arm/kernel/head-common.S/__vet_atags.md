__vet_atags
========================================

atags的地址是由bootloader传递给kernel的，在我们的bootloader中其构建atags的过程如下:

https://github.com/leeminghao/doc-linux/blob/master/bootloader/lk/apps/aboot/aboot_c/generate_atags.md

这里对atag的检查主要检查其是不是以ATAG_CORE开头，size对不对等.

path: arch/arm/kernel/head-common.S
```
/* Determine validity of the r2 atags pointer.  The heuristic requires
 * that the pointer be aligned, in the first 16k of physical RAM and
 * that the ATAG_CORE marker is first and present.  If CONFIG_OF_FLATTREE
 * is selected, then it will also accept a dtb pointer.  Future revisions
 * of this function may be more lenient with the physical address and
 * may also be able to move the ATAGS block if necessary.
 *
 * Returns:
 *  r2 either valid atags pointer, valid dtb pointer, or zero
 *  r5, r6 corrupted
 */
__vet_atags:
    tst    r2, #0x3            @ aligned?
    bne    1f

    ldr    r5, [r2, #0]
#ifdef CONFIG_OF_FLATTREE
    ldr    r6, =OF_DT_MAGIC        @ is it a DTB?
    cmp    r5, r6
    beq    2f
#endif
    cmp    r5, #ATAG_CORE_SIZE        @ is first tag ATAG_CORE?
    cmpne  r5, #ATAG_CORE_SIZE_EMPTY
    bne    1f
    ldr    r5, [r2, #4]
    ldr    r6, =ATAG_CORE
    cmp    r5, r6
    bne    1f

2:  mov    pc, lr                @ atag/dtb pointer is ok

1:  mov    r2, #0
    mov    pc, lr
ENDPROC(__vet_atags)
```