local_irq_disable
========================================

path: include/linux/irqflags.h
```
/*
 * The local_irq_*() APIs are equal to the raw_local_irq*()
 * if !TRACE_IRQFLAGS.
 */
#ifdef CONFIG_TRACE_IRQFLAGS
...
#define local_irq_disable()  \
    do { raw_local_irq_disable(); trace_hardirqs_off(); } while (0)
...
#else /* !CONFIG_TRACE_IRQFLAGS */

...
#define local_irq_disable()    do { raw_local_irq_disable(); } while (0)
...
#endif /* CONFIG_TRACE_IRQFLAGS */
```