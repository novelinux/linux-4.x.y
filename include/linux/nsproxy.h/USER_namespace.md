User namespaces
========================================

User namespace主要隔离了安全相关的标识符（identifiers）和属性（attributes），包括用户ID、
用户组ID、root目录、key（指密钥）以及特殊权限。说得通俗一点，一个普通用户的进程通过clone()
创建的新进程在新user namespace中可以拥有不同的用户和用户组。这意味着一个进程在容器外属于一个
没有特权的普通用户，但是他创建的容器进程却属于拥有所有权限的超级用户，这个技术为容器提供了
极大的自由。

User namespace是目前的六个namespace中最后一个支持的，并且直到Linux内核3.8版本的时候还未完全实现
（还有部分文件系统不支持）。因为user namespace实际上并不算完全成熟，很多发行版担心安全问题，
在编译内核的时候并未开启USER_NS。实际上目前Docker也还不支持user namespace，但是预留了相应接口，
相信在不久后就会支持这一特性。所以在进行接下来的代码实验时，请确保你系统的Linux内核版本高于3.8
并且内核编译时开启了USER_NS（如果你不会选择，可以使用Ubuntu14.04）。

Linux中，特权用户的user ID就是0，演示的最终我们将看到user ID非0的进程启动user namespace
后user ID可以变为0。使用user namespace的方法跟别的namespace相同，即调用clone()或unshare()时加入
CLONE_NEWUSER标识位。

实例
----------------------------------------

```
#define _GNU_SOURCE
#include <sys/types.h>
#include <sys/wait.h>
#include <stdio.h>
#include <sched.h>
#include <signal.h>
#include <unistd.h>

#define STACK_SIZE (1024 * 1024)

static char child_stack[STACK_SIZE];
char* const child_args[] = {
    "/bin/bash",
    NULL
};

static int child_main(void* args)
{
    printf("in child\n");
    printf("eUID=%u, eGID=%u\n", getuid(), getgid());
    execv(child_args[0], child_args);
    printf("child failed\n");
    return 1;
}

int main(int argc, char *argv[])
{
    printf("starting ...\n");
    int child_pid = clone(child_main, child_stack + STACK_SIZE,
                          CLONE_NEWUSER | SIGCHLD,
                          NULL);
    waitpid(child_pid, NULL, 0);
    printf("exited\n");
    return 0;
}
```

先查看一下当前用户的uid和guid，请注意此时我们是普通用户。

```
$ id -u
1000
$ id -g
1000
```

然后我们开始编译运行，并进行新建的user namespace:

```
$ id -u
65534
$ id -g
65534
```

通过验证我们可以得到以下信息:

* user namespace被创建后，第一个进程被赋予了该namespace中的全部权限，这样这个init进程就可以完成
  所有必要的初始化工作，而不会因权限不足而出现错误。

* 我们看到namespace内部看到的UID和GID已经与外部不同了，默认显示为65534，表示尚未与外部
namespace用户映射。我们需要对user namespace内部的这个初始user和其外部namespace某个用户建立映射，
这样可以保证当涉及到一些对外部namespace的操作时，系统可以检验其权限（比如发送一个信号或操作某个
文件）。同样用户组也要建立映射。

* 还有一点虽然不能从输出中看出来，但是值得注意。用户在新namespace中有全部权限，但是他在创建他的
父namespace中不含任何权限。就算调用和创建他的进程有全部权限也是如此。所以哪怕是root用户调用了
clone()在user namespace中创建出的新用户在外部也没有任何权限。

* 最后，user namespace的创建其实是一个层层嵌套的树状结构。最上层的根节点就是root namespace，
新创建的每个user namespace都有一个父节点user namespace以及零个或多个子节点user namespace，
这一点与PID namespace非常相似。

接下来我们就要进行用户绑定操作，通过在/proc/[pid]/uid_map和/proc/[pid]/gid_map两个文件中写入
对应的绑定信息可以实现这一点，格式如下:

```
ID-inside-ns   ID-outside-ns   length
```

写这两个文件需要注意以下几点。

* 这两个文件只允许由拥有该user namespace中CAP_SETUID权限的进程写入一次，不允许修改。
* 写入的进程必须是该user namespace的父namespace或者子namespace。

第一个字段ID-inside-ns表示新建的user namespace中对应的user/group ID，
第二个字段ID-outside-ns表示namespace外部映射的user/group ID。
最后一个字段表示映射范围，通常填1，表示只映射一个，如果填大于1的值，则按顺序建立一一映射。
明白了上述原理，我们再次修改代码，添加设置uid和guid的函数。

```
void set_uid_map(pid_t pid, int inside_id, int outside_id, int length)
{
    char path[256];
    sprintf(path, "/proc/%d/uid_map", getpid());
    FILE* uid_map = fopen(path, "w");
    fprintf(uid_map, "%d %d %d", inside_id, outside_id, length);
    fclose(uid_map);
}

void set_gid_map(pid_t pid, int inside_id, int outside_id, int length)
{
    char path[256];
    sprintf(path, "/proc/%d/gid_map", getpid());
    FILE* gid_map = fopen(path, "w");
    fprintf(gid_map, "%d %d %d", inside_id, outside_id, length);
    fclose(gid_map);
}

static int child_main(void* args)
{
    printf("in child\n");
    set_uid_map(getpid(), 0, 1000, 1);
    set_gid_map(getpid(), 0, 1000, 1);
    ...
}
```

至此，你就已经完成了绑定的工作，可以看到演示全程都是在普通用户下执行的。最终实现了在
user namespace中成为了root而对应到外面的是一个uid为1000的普通用户。

如果你要把user namespace与其他namespace混合使用，那么依旧需要root权限。解决方案可以是先以
普通用户身份创建user namespace，然后在新建的namespace中作为root再clone()进程加入其他类型的
namespace隔离。
