v7_crval
========================================

path: arch/arm/mm/proc-v7-2level.S
```
    __CPUINIT

    /*   AT
     *  TFR   EV X F   I D LR    S
     * .EEE ..EE PUI. .T.T 4RVI ZWRS BLDP WCAM
     * rxxx rrxx xxx0 0101 xxxx xxxx x111 xxxx < forced
     *    1    0 110       0011 1100 .111 1101 < we want
     */
    .align    2
    .type    v7_crval, #object
v7_crval:
    crval    clear=0x0120c302, mmuset=0x10c03c7d, ucset=0x00c01c7c

    .previous
```

CP15
----------------------------------------

https://github.com/novelinux/arch-arm-common/tree/master/CP15.md

MMU
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/mm/mmu.c