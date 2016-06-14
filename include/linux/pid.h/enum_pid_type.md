enum pid_type
========================================

path: include/linux/pid.h
```
enum pid_type
{
    PIDTYPE_PID,
    PIDTYPE_PGID,
    PIDTYPE_SID,
    PIDTYPE_MAX
};
```

枚举类型中定义的ID类型不包括线程组ID！这是因为线程组ID无非是线程组组长的PID而已，
因此再单独定义一项是不必要的。