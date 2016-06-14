SYSCALL_DEFINE
========================================

path: include/linux/syscalls.h
```
#define SYSCALL_DEFINE0(sname)                    \
    SYSCALL_METADATA(_##sname, 0);                \
    asmlinkage long sys_##sname(void)

#define SYSCALL_DEFINE1(name, ...) SYSCALL_DEFINEx(1, _##name, __VA_ARGS__)
#define SYSCALL_DEFINE2(name, ...) SYSCALL_DEFINEx(2, _##name, __VA_ARGS__)
#define SYSCALL_DEFINE3(name, ...) SYSCALL_DEFINEx(3, _##name, __VA_ARGS__)
#define SYSCALL_DEFINE4(name, ...) SYSCALL_DEFINEx(4, _##name, __VA_ARGS__)
#define SYSCALL_DEFINE5(name, ...) SYSCALL_DEFINEx(5, _##name, __VA_ARGS__)
#define SYSCALL_DEFINE6(name, ...) SYSCALL_DEFINEx(6, _##name, __VA_ARGS__)

#define SYSCALL_DEFINEx(x, sname, ...)                \
    SYSCALL_METADATA(sname, x, __VA_ARGS__)            \
    __SYSCALL_DEFINEx(x, sname, __VA_ARGS__)

#define __PROTECT(...) asmlinkage_protect(__VA_ARGS__)
#define __SYSCALL_DEFINEx(x, name, ...)                    \
    asmlinkage long sys##name(__MAP(x,__SC_DECL,__VA_ARGS__))    \
        __attribute__((alias(__stringify(SyS##name))));        \
    static inline long SYSC##name(__MAP(x,__SC_DECL,__VA_ARGS__));    \
    asmlinkage long SyS##name(__MAP(x,__SC_LONG,__VA_ARGS__));    \
    asmlinkage long SyS##name(__MAP(x,__SC_LONG,__VA_ARGS__))    \
    {                                \
        long ret = SYSC##name(__MAP(x,__SC_CAST,__VA_ARGS__));    \
        __MAP(x,__SC_TEST,__VA_ARGS__);                \
        __PROTECT(x, ret,__MAP(x,__SC_ARGS,__VA_ARGS__));    \
        return ret;                        \
    }                                \
    static inline long SYSC##name(__MAP(x,__SC_DECL,__VA_ARGS__))
```