__define_initcall
========================================

path: include/linux/init.h
```
#ifdef CONFIG_LTO
/* Work around a LTO gcc problem: when there is no reference to a variable
 * in a module it will be moved to the end of the program. This causes
 * reordering of initcalls which the kernel does not like.
 * Add a dummy reference function to avoid this. The function is
 * deleted by the linker.
 */
#define LTO_REFERENCE_INITCALL(x) \
	; /* yes this is needed */			\
	static __used __exit void *reference_##x(void)	\
	{						\
		return &x;				\
	}
#else
#define LTO_REFERENCE_INITCALL(x)
#endif

/* initcalls are now grouped by functionality into separate
 * subsections. Ordering inside the subsections is determined
 * by link order.
 * For backwards compatibility, initcall() puts the call in
 * the device init subsection.
 *
 * The `id' arg to __define_initcall() is needed so that multiple initcalls
 * can point at the same handler without causing duplicate-symbol build errors.
 */

#define __define_initcall(fn, id) \
    static initcall_t __initcall_##fn##id __used \
    __attribute__((__section__(".initcall" #id ".init"))) = fn; \
    LTO_REFERENCE_INITCALL(__initcall_##fn##id)
```
