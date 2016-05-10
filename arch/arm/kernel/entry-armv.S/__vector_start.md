__vector_start
========================================

Linux kernel ARM异常向量表:

__vector_start
----------------------------------------

path: arch/arm/kernel/entry-armv.S中:
```
__vectors_start:
    W(b)    vector_rst
    W(b)    vector_und
    W(ldr)  pc, __vectors_start + 0x1000 @(__stubs_start == vector + 0x1000)
    W(b)    vector_pabt
    W(b)    vector_dabt
    W(b)    vector_addrexcptn
    W(b)    vector_irq
    W(b)    vector_fiq
```

这里__vectors_start + 0x1000地址中存的又是vector_swi的地址：

path: arch/arm/kernel/vmlinux.lds.S
```
    /*
     * The vectors and stubs are relocatable code, and the
     * only thing that matters is their relative offsets
     */
    __vectors_start = .;
    .vectors 0 : AT(__vectors_start) {
        *(.vectors)
    }
    . = __vectors_start + SIZEOF(.vectors);
    __vectors_end = .;

    __stubs_start = .;
    .stubs 0x1000 : AT(__stubs_start) {
        *(.stubs)
    }
    . = __stubs_start + SIZEOF(.stubs);
    __stubs_end = .;
```

path: arch/arm/kernel/entry-armv.S
```
    .section .stubs, "ax", %progbits
__stubs_start:
    @ This must be the first word
    .word    vector_swi
```

### vector_swi

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/kernel/entry-common.S/vector_swi.md
