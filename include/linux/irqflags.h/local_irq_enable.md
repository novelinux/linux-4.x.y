local_irq_enable
========================================

path: include/linux/irqflags.h
```
/*
 * The local_irq_*() APIs are equal to the raw_local_irq*()
 * if !TRACE_IRQFLAGS.
 */
#ifdef CONFIG_TRACE_IRQFLAGS
#define local_irq_enable()   \
    do { trace_hardirqs_on(); raw_local_irq_enable(); } while (0)
...
#else /* !CONFIG_TRACE_IRQFLAGS */

#define local_irq_enable()    do { raw_local_irq_enable(); } while (0)
...
#endif /* CONFIG_TRACE_IRQFLAGS */
```