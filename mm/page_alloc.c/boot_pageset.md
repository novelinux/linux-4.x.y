boot_pageset
========================================

path: mm/page_alloc.c
```
/*
 * Boot pageset table. One per cpu which is going to be used for all
 * zones and all nodes. The parameters will be set in such a way
 * that an item put on a list will immediately be handed over to
 * the buddy list. This is safe since pageset manipulation is done
 * with interrupts disabled.
 *
 * The boot_pagesets must be kept even after bootup is complete for
 * unused processors and/or zones. They do play a role for bootstrapping
 * hotplugged processors.
 *
 * zoneinfo_show() and maybe other functions do
 * not check if the processor is online before following the pageset pointer.
 * Other parts of the kernel may not check if the zone is available.
 */
static DEFINE_PER_CPU(struct per_cpu_pageset, boot_pageset);
```

DEFINE_PER_CPU
----------------------------------------

https://github.com/novelinux/linux-4.x.y/blob/master/include/linux/percpu-defs.h/DEFINE_PER_CPU.md
