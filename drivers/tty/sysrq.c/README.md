# sysrq

## enable

```
#  cat /proc/sys/kernel/sysrq
0
# echo 1 > /proc/sys/kernel/sysrq
```

## trigger

```
# echo u > /proc/sysrq-trigger
```

## keys

path: drivers/tty/sysrq.c
