vector_swi
========================================

swi中断:

https://github.com/novelinux/arch-arm-common/tree/master/swi.md

当使用swi触发软中断的时候将会调用vector_swi处的中断处理函数来处理对应的软件中断.

Push Stack
----------------------------------------

path: arch/arm/kernel/entry-common.S
```
ENTRY(vector_swi)
  @这个栈帧大小正好是struct pt_regs的大小. struct pt_regs中保存的是
　@线程用户态的寄存器上下文(模式上下文).
  sub    sp, sp, #S_FRAME_SIZE
  @ 将r0-r12寄存器压入内核栈中
  stmia  sp, {r0 - r12}            @ Calling r0 - r12
  @ 将用户态的sp、lr压入内核栈中
  ARM(   add    r8, sp, #S_PC    )
  ARM(   stmdb    r8, {sp, lr}^  )    @ Calling sp, lr
  THUMB( mov    r8, sp           )
  THUMB( store_user_sp_lr r8, r10, S_SP )    @ calling sp, lr
  @ sprs_svc中保存的是调用swi指令前的cpsr值，这里将它保存在寄存器r8中
  mrs    r8, spsr            @ called from non-FIQ mode, so ok.
  @ lr中的值是swi指令的下一行，也就是系统调用的用户态返回地址。将其压入内核栈中
  str    lr, [sp, #S_PC]            @ Save calling PC
  @ 将调用swi指令前的cpsr值压入内核栈中
  str    r8, [sp, #S_PSR]        @ Save CPSR
  @ 将r0压入内核栈中
  str    r0, [sp, #S_OLD_R0]        @ Save OLD_R0
  zero_fp
  ...
  /* Legacy ABI only. */
  ldr scno, [lr, #-4]  @ get SWI instruction
  ...
```

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/kernel/asm-offsets.c/pt_regs_offsets.md

enable_irq
----------------------------------------

```
  enable_irq
```

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/include/asm/assembler.h/enable_irq.md

get_thread_info
----------------------------------------

```
  get_thread_info tsk
```

sys_call_table
----------------------------------------

在linux arm中，会查询sys_call_table跳转表,这个表中存储的是一系列的函数指针,这些
指针就是系统调用函数的指针.

```
  adr    tbl, sys_call_table @ load syscall table pointer
  ...
  cmp    scno, #NR_syscalls        @ check upper syscall limit
  @ 这里先设置系统调用执行函数sys_xxx()的返回地址为ret_fast_syscall
  @ 这是设置的是当前线程lr_svc寄存器,当下次通过__switch_to恢复
  @ 当前线程的上下文(cpu_context)时首先调用ret_fast_syscall来恢复其用户态
  @ 的线程上下文(struct pt_regs).
  adr    lr, BSYM(ret_fast_syscall)    @ return address
  @ 以下就是根据系统调用号调用具体的执行函数。
  ldrcc  pc, [tbl, scno, lsl #2]        @ call sys_* routine
  ...
ENDPROC(vector_swi)
```

注意:

* 1.这里的sp已经是sp_svc了，也就是当前线程的内核栈了。
* 2.前面几句代码，就是保存调用swi之前的CPU的寄存器组。。
  分别为r0～r12、、sp、lr、pc、cpsr和r0,这里r0会存两个位置，一个代表第一个参数，另一个代表返回值。
  为什么会有两个r0？
* 3. {sp, lr}^中的"^"表示这里的sp和lr是用户态的寄存器。

### tbl, scno

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/kernel/entry-header.S/scno_tbl_why_tsk.md

ret_fast_syscall
----------------------------------------

当系统调用退出时，将会调用ret_fast_syscall:

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/kernel/entry-common.S/ret_fast_syscall.md