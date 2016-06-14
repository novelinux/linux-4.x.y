sys_call_table
========================================

path: arch/arm/kernel/entry-common.S
```
    .type    sys_call_table, #object
ENTRY(sys_call_table)
#include "calls.S"
```

calls.S
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/kernel/calls.S/calls.S.md
