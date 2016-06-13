struct new_utsname
========================================

path: include/uapi/linux/utsname.h
```
#define __NEW_UTS_LEN 64
...
struct new_utsname {
    char sysname[__NEW_UTS_LEN + 1];
    char nodename[__NEW_UTS_LEN + 1];
    char release[__NEW_UTS_LEN + 1];
    char version[__NEW_UTS_LEN + 1];
    char machine[__NEW_UTS_LEN + 1];
    char domainname[__NEW_UTS_LEN + 1];
};
```

各个字符串分别存储了系统的名称（Linux...）, 内核发布版本,
机器名，等等。使用uname工具可以取得这些属性的当前值，
也可以在/proc/sys/kernel/中看到：

```
root@cancro:/ # cat /proc/sys/kernel/ostype
Linux
root@cancro:/ # cat /proc/sys/kernel/osrelease
3.4.0-g0c665cd-00547-g2e99435-dirty
```
