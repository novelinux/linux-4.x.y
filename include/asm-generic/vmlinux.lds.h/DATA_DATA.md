DATA_DATA
========================================

path: include/asm-generic/vmlinux.lds.h
```
/* .data section */
#define DATA_DATA							\
	*(.data)							\
	*(.ref.data)							\
	*(.data..shared_aligned) /* percpu related */			\
	MEM_KEEP(init.data)						\
	MEM_KEEP(exit.data)						\
	*(.data.unlikely)						\
	STRUCT_ALIGN();							\
	*(__tracepoints)						\
	/* implement dynamic printk debug */				\
	. = ALIGN(8);                                                   \
	VMLINUX_SYMBOL(__start___jump_table) = .;                       \
	*(__jump_table)                                                 \
	VMLINUX_SYMBOL(__stop___jump_table) = .;                        \
	. = ALIGN(8);							\
	VMLINUX_SYMBOL(__start___verbose) = .;                          \
	*(__verbose)                                                    \
	VMLINUX_SYMBOL(__stop___verbose) = .;				\
	LIKELY_PROFILE()		       				\
	BRANCH_PROFILE()						\
	TRACE_PRINTKS()							\
	TRACEPOINT_STR()
```