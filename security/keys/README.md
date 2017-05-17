# Linux 密钥保留服务入门

Linux 密钥保留服务（Linux key retention service）是在 Linux 2.6 中引入的，它的主要意图是在
Linux 内核中缓存身份验证数据。远程文件系统和其他内核服务可以使用这个服务来管理密码学、身份验证标记、
跨域用户映射和其他安全问题。它还使 Linux 内核能够快速访问所需的密钥，并可以用来将密钥操作（比如添加、更新和删除）委托给用户空间。

## 什么是密钥？

密钥（key）是一组密码学数据、身份验证标记或某些相似的元素，它在内核中由 struct key 表示。

path: include/linux/key.h
```
struct key {
      atomic_t                 usage;       /* number of references */
      key_serial_t           serial;        /* key serial number */
      struct key_type      *type;        /* type of key */
      time_t                     expiry;  /* time at which key expires (or 0) */
      uid_t                       uid;           /* UID */
      gid_t                       gid;           /* GID */
      key_perm_t            perm;        /* access permissions */
      unsigned short       quotalen;   /* length added to quota */
      unsigned short       datalen;     /* payload data length
      char                      *description;
      union {
          unsigned long             value;
          void                            *data;
          struct keyring_list       *subscriptions;
      } payload;                                 /* Actual security data */
      ....
      ....
};
```

### 密钥的属性

密钥具有以下属性：

* 序号（Serial number）：一个惟一的 32 位非零正数。
* 类型（Type）：Linux 密钥保留服务定义两个标准密钥类型：user 和 keyring。
  要添加新的密钥类型，必须由一个内核服务注册它。用户空间程序不允许创建新的密钥类型。
  密钥类型在内核中由 struct key_type 表示.

path: include/linux/key.h
```
struct key_type {
    const char *name;
    size_t def_datalen;

	/* Operations that can be defined for a key_type */
    int (*instantiate)(struct key *key, const void *data, size_t datalen);
    int (*update)(struct key *key, const void *data, size_t datalen);
    int (*match)(const struct key *key, const void *desc);
    void (*revoke)(struct key *key);
    void (*destroy)(struct key *key);
    void (*describe)(const struct key *key, struct seq_file *p);
    long (*read)(const struct key *key, char __user *buffer, size_t buflen);
    ....
    ....
};
```

还可以将一组操作与一个密钥类型相关联。key_type 可以定义以下操作：

```
* instantiate 创建指定类型的一个新密钥。
* describe 输出描述这个密钥的文本。
* match 根据描述搜索密钥。
* destroy 清除与一个密钥相关的所有数据。
* request_key 搜索密钥。
* revoke 清除密钥数据并将密钥的状态改为 REVOKED。
* read 读取密钥数据。
* update 修改密钥。
```

* 描述（Description）：一个描述密钥的可输出字符串。这个属性还可以用来执行搜索操作。
* 访问控制信息（Access control information）：每个密钥有一个所有者 ID、一个 GID 和一个权限掩码，
  权限掩码表示如何响应用户级或内核级程序。权限掩码给四个可能的密钥访问者类型各分配 8 位：所有者、用户、组和其他。在这 8 位中，只定义了 6 位。
  可能的权限如下：

```
View 允许权限持有者查看密钥属性。
Read 允许权限持有者读取密钥并列出 keyring 的密钥。
Write 允许权限持有者修改密钥或 keyring 的有效内容和修改链接的密钥。
Search 允许权限持有者搜索 keyring 和寻找密钥。
Link 允许权限持有者将特定的密钥或 keyring 链接到 keyring。
Set Attribute 允许权限持有者设置密钥的 UID、GID 和权限掩码。
```

* 过期时间（Expiry Time）：密钥的生存期。密钥也可以是永久的。
* 有效内容（Payload）：实际的安全内容。可以通过 struct key_type 定义的操作用数据对有效内容进行实例化，还可以读取数据或修改数据。对于内核来说，有效内容仅仅是一组数据。
* 状态（State）：密钥可以处于以下状态：
```
UNINSTANTIATED：已经创建了密钥，但是还没有附加任何数据。
INSTANTIATED：密钥已经实例化并附加了数据；这是一个完整的 状态。
NEGATIVE：这是一个临时状态，表示前面对用户空间的调用失败了。
EXPIRED：表示密钥已经超过了预定义的生存期。
REVOKED：一个用户空间操作将密钥转移到这个状态。
DEAD：key_type 取消了注册。
```

### 密钥类型

有两种预定义的密钥类型：keyring 和 user。
keyring 包含一组到其他密钥或 keyring 的链接。有六种标准的 keyring：

* 线程特有的
* 进程特有的
* 会话特有的
* 用户特有的会话
* 用户默认的会话
* 组特有的（还未实现）

限额:

对于一个用户可以拥有的密钥和 keyring 的数量有限制（密钥数量限额），对于在密钥描述和有效内容中使用的信息量也有限制（密钥大小限额）。
进程特有的和线程特有的 keyring 不在用户限额的范围内。只有前三个 keyring 被自动搜索，自动搜索会按照次序进行。
第四种类型（用户特有的会话 keyring）不被直接搜索，但是，它通常会链接到一个会话特有的 keyring。登录进程（比如 PAM）将绑定到用户
默认的会话 keyring，直到创建另一个会话为止。

用户密钥由用户空间程序操作。

## 三个新的系统调用

Linux 密钥保留服务提供三个新的系统调用，用来在用户空间中操作密钥。

### add_key

```
key_serial_t add_key(const char *type, const char *desc,
                     const void *payload, size_t plen,
                     key_serial_t ring);
```

add_key 系统调用用来创建类型为 type、长度为 plen 的密钥。密钥描述由 desc 定义，
它的有效内容由 payload 指定。密钥链接到 keyring ring。密钥类型可以是 user 或 keyring。
其他任何密钥类型必须已经通过内核服务向内核注册，然后才能使用。如果密钥是 keyring 类型的，有效内容就应该是 NULL，plen 应该是零。

### request_key

```
key_serial_t request_key(const char *type, const char *desc,
                         const char *callout_info,
                         key_serial_t dest_keyring);
```
request_key 系统调用搜索一个进程 keyring，寻找一个密钥。
request_key 算法:

search_into_each_subscribed_keyrings {
   if(key is found){
     return(found key);
   } else {
     if(callout_info is NULL){
        return(ERROR);
     } else {
        Execute /sbin/request-key and pass callout_info as argument;
     }
   }
}
关于 request_key 算法的工作原理的详细信息，请参考 Documentation/keys-request-key.txt（参见 参考资料 中的链接）。

### keyctl

最后，系统调用 keyctl 提供许多用来管理密钥的函数。可以根据传递给 keyctl 的第一个参数在密钥上执行各种操作。下面列出 keyctl 的一部分操作：
KEYCTL_DESCRIBE 描述一个密钥。
KEYCTL_READ 从一个密钥读取有效内容数据。
KEYCTL_UPDATE 更新指定的密钥。
KEYCTL_LINK 将一个密钥链接到一个 keyring。
KEYCTL_UNLINK 将密钥或 keyring 与另一个 keyring 的链接取消。
KEYCTL_JOIN_SESSION_KEYRING 将一个会话 keyring 替换为新的会话 keyring。
KEYCTL_REVOKE 取消一个密钥。
KEYCTL_CHOWN 修改密钥的所有者。
KEYCTL_SETPERM 修改密钥的权限掩码。
KEYCTL_CLEAR 清除一个 keyring。
KEYCTL_SEARCH 在一个 keyring 树中搜索密钥。
KEYCTL_INSTANTIATE 对部分构造好的密钥进行实例化。
KEYCTL_NEGATE 取消对部分构造好的密钥的实例化。
关于 keyctl 的原型和 keyctl 可以执行的其他操作的更多信息，请参考 Linux 手册页。

## 管理密钥的内核 API

下面是几个用来管理密钥的最重要的 Linux 内核 API。要想了解更全面的信息，请下载并参考 Linux 密钥实现源代码文件（参见下面的 下载）。

* register_key_type

用来定义新的密钥类型:
```
int register_key_type(struct key_type *type)
```

* unregister_key_type

用来取消密钥类型的注册：
```
void unregister_key_type(struct key_type *type);
```

* key_put

发布一个密钥：
```
void key_put(struct key *key);
```

* request_key

搜索与给定的描述匹配的密钥：
```
struct key *request_key(const struct key_type *type,
                        const char *description,
                        const char *callout_string);
```

* key_alloc

分配指定类型的密钥：
```
struct key *key_alloc(struct key_type *type, const char *desc,
                      uid_t uid, gid_t gid, struct task_struct *ctx,
                      key_perm_t perm, unsigned long flags);
```

* key_instantiate_and_link

对密钥进行实例化并将它链接到目标 keyring：

```
int key_instantiate_and_link(struct key *key,  const void *data,
                             size_t datalen, struct key *keyring,
                             struct key *instkey);
```

## 启用密钥服务

因为 Linux 密钥保留服务仍然非常新，在默认情况下 Linux 内核中关闭了这个服务。要想启用密钥服务，必须使用 CONFIG_KEYS=y 选项对内核进行配置。
可以在内核编译的 make *config 步骤中 Security options 下面找到这个选项。

```
#
# Security options
#
CONFIG_KEYS=y
CONFIG_KEYS_DEBUG_PROC_KEYS=y
CONFIG_SECURITY=y
CONFIG_SECURITY_NETWORK=y
CONFIG_SECURITY_CAPABILITIES=y
```

密钥的源代码被组织在目录 linux-2.6.x/security/keys 中。
接下来，需要 下载并安装 keyutils 包。keyutils 包含 keyctl 命令，可以使用这个命令在密钥上执行各种操作。前面已经列出了 keyctl 的一部分操作。更多信息参见 Linux 手册页。

## 创建新的密钥类型

示例程序有两个组件：一个内核模块和一个用户空间程序。这个内核模块注册一个新的密钥类型。这个用户空间程序在预定义的 proc-entries 上执行 ioctl，
这会导致对内核模块的调用。这个调用会产生一个新的密钥。然后，一个 “bash” shell 返回给用户，它带有新的会话 keyring 和链接到这个 keyring 的新类型的密钥。
因为这个用户空间程序将执行 ioctl，内核模块必须注册 proc_ioctl() 函数来处理 ioctl 请求。所有 ioctl 通信都使用 /proc 接口来进行。

```
struct key_type new_key_type = {
   .name = "mykey",
   .instantiate = instantiate_key,
   .describe = key_desc,
   .destroy = key_destroy,
   .match = key_match,
};
```

然后，模块在它的 init 函数中调用 register_key_type() 来注册这个新密钥类型（名为 mykey）。当内核模块收到 ioctl 请求时，
它首先调用 key_alloc() 来分配一个新的密钥，从而创建一个会话 keyring。在成功调用 key_alloc() 之后，
调用 key_instantiate_and_link() 对密钥进行实例化。在创建并实例化会话 keyring 之后，为用户的会话创建密钥。
同样，依次调用 key_alloc() 和 key_instantiate_and_link()。成功完成这些调用之后，用户空间会话就有了一个新密钥。

## 使用模块

创建了新的密钥类型之后，我们来试用一下这个内核模块。模块中的一个基本操作是查看一个进程与哪些 keyring 相关联，
以及这些 keyring 包含哪些密钥和其他 keyring。调用 keyctl show 就可以在树结构中显示密钥。清单 6 显示在运行程序之前密钥的状态。

```
# keyctl show
Session Keyring
       -3 --alswrv      0     0  keyring: _ses.1976
        2 --alswrv      0     0   \_ keyring: _uid.0
# insmod ./kernel.land/newkey.ko
Loading the module ...
Registered "learning_key"
# ./user.land/session

In /var/log/message, you will see similar output
Installing session keyring:
keyring allocated successfully.
keyring instantiated and linked successfully.
New session keyring installed successfully.
key of new type allocated successfully.
New key type linked to current session.
# keyctl show
Session Keyring
       -3 --alswrv      0     0  keyring: session.2621
 39044642 --alswrv      0     0   \_ mykey: New key type

# cat /proc/keys
00000001 I-----     1 perm 1f3f0000     0     0 keyring   _uid_ses.0: 1/4
00000002 I-----     5 perm 1f3f0000     0     0 keyring   _uid.0: empty
0253c622 I--Q--     1 perm 3f3f0000     0     0 mykey   New key type: 0
11a490da I--Q--     2 perm 3f3f0000     0     0 keyring   session.2621: 1/4
13670439 I--Q--     2 perm 1f3f0000     0     0 keyring   _ses.1977: 1/4
159d39b8 I--Q--     5 perm 1f3f0000     0     0 keyring   _ses.1976: 1/4
3a14f259 I--Q--     3 perm 1f3f0000     0     0 keyring   _ses.1978: 1/4

# cat /proc/key-users
    0:     8 7/7 5/100 136/10000
   43:     2 2/2 2/100 56/10000
   48:     2 2/2 2/100 56/10000
   81:     2 2/2 2/100 56/10000
  786:     4 4/4 4/100 113/10000

"keyctl describe <Key>" command gives the description of key.

# keyctl describe -3
       -3: alswrvalswrv------------     0     0 keyring: session.2621
# keyctl describe 39044642
 39044642: alswrvalswrv------------     0     0 mykey: New key type
$ keyctl search -3 mykey "New key type"
39044642
# exit
exit
Now back to our previous state
# keyctl show
Session Keyring
       -3 --alswrv      0     0  keyring: _ses.1976
        2 --alswrv      0     0   \_ keyring: _uid.0
# rmmod ./kernel.land/newkey.ko
Unloading the module.
Unregistered "learning_key"
```

## 与密钥相关的 proc 文件

/proc 中添加了两个文件来管理密钥：/proc/keys 和 /proc/key-users。我们来仔细看看这些文件。

### /proc/keys

如果一个进程希望了解它可以查看哪些密钥，它可以通过读取 /proc/keys 获得这些信息。在配置内核时，必须启用这个文件，因为它允许任何用户列出密钥数据库。

```
[root@phoenix set.5]# cat /proc/keys
00000001 I-----  1     perm    1f3f0000      0    0    keyring    _uid_ses.0 : 1/4
00000002 I-----  5     perm    1f3f0000      0    0    keyring    _uid.0     : empty
13670439 I--Q--  2     perm    1f3f0000      0    0    keyring    _ses.1977  : 1/4
159d39b8 I--Q--  6     perm    1f3f0000      0    0    keyring    _ses.1976  : 1/4
3a14f259 I--Q--  3     perm    1f3f0000      0    0    keyring    _ses.1978  : 1/4
[Serial][Flags][Usage][Expiry][Permissions][UID][GID][TypeName][Description] :[Summary]
```

*Source: linux_kernel_source/security/keys/proc.c:proc_keys_show()
在以上文件中看到的大多数字段来自 include/linux/key.h 中定义的 struct key。

```
          I        Instantiated
          R        Revoked
          D        Dead
          Q        Contributes to user's quota
          U        Under construction by callback to user-space
          N        Negative key
```

### /proc/key-users

```
[root@phoenix set.5]# cat /proc/key-users
    0:     6 5/5 3/100 90/10000
   43:     2 2/2 2/100 56/10000
   48:     2 2/2 2/100 56/10000
   81:     2 2/2 2/100 56/10000
  786:     4 4/4 4/100 113/10000
```

```
<UID>                     User ID
<usage>                 Usage count
<inst>/<keys>      Total number of keys and number instantiated
<keys>/<max>     Key count quota
<bytes><max>     Key size quota
```
大多数字段是 security/keys/internal.h 中定义的 struct key_user 的字段。

# Reference

https://www.ibm.com/developerworks/cn/linux/l-key-retention.html
