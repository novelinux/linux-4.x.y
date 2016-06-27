TI_XXX
========================================

path: arch/arm/kernel/asm-offsets.c
```
  ...
#ifdef CONFIG_CC_STACKPROTECTOR
  DEFINE(TSK_STACK_CANARY,    offsetof(struct task_struct, stack_canary));
#endif
  ...
  DEFINE(TI_TASK,        offsetof(struct thread_info, task));
  ...
  DEFINE(TI_CPU_DOMAIN,  offsetof(struct thread_info, cpu_domain));
  DEFINE(TI_CPU_SAVE,    offsetof(struct thread_info, cpu_context));
  ...
  DEFINE(TI_TP_VALUE,    offsetof(struct thread_info, tp_value));
```