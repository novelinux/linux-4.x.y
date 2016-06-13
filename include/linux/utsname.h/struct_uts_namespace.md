struct uts_namespace
========================================

kref
----------------------------------------

path: include/linux/utsname.h
```
struct uts_namespace {
    struct kref kref;
```

kref是一个嵌入的引用计数器，可用于跟踪内核中有多少地方使用了
struct uts_namespace的实例.

name
----------------------------------------

```
    struct new_utsname name;
```

uts_namespace所提供的属性信息本身包含在struct new_utsname中：

user_ns
----------------------------------------

```
    struct user_namespace *user_ns;
```

struct user_namespace保存的用于限制每个用户资源使用的信息。

ns
----------------------------------------

```
    struct ns_common ns;
};
```