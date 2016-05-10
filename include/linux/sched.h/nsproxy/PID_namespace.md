PID namespace
========================================

PID namespace隔离非常实用，它对进程PID重新标号，即两个不同namespace下的进程可以有同一个PID。
每个PID namespace都有自己的计数程序。内核为所有的PID namespace维护了一个树状结构，最顶层的是
系统初始时创建的，我们称之为root namespace。他创建的新PID namespace就称之为child namespace
（树的子节点），而原先的PID namespace就是新创建的PID namespace的parent namespace（树的父节点）。
通过这种方式，不同的PID namespaces会形成一个等级体系。所属的父节点可以看到子节点中的进程，并可以
通过信号等方式对子节点中的进程产生影响。反过来，子节点不能看到父节点PID namespace中的任何内容。
由此产生如下结论:

每个PID namespace中的第一个进程"PID 1"，都会像传统Linux中的init进程一样拥有特权，起特殊作用。
一个namespace中的进程，不可能通过kill或ptrace影响父节点或者兄弟节点中的进程，因为其他节点的
PID在这个namespace中没有任何意义。如果你在新的PID namespace中重新挂载/proc文件系统，会发现其下
只显示同属一个PID namespace中的其他进程。在root namespace中可以看到所有的进程，并且递归包含所有
子节点中的进程。到这里，可能你已经联想到一种在外部监控Docker中运行程序的方法了，就是监控
Docker Daemon所在的PID namespace下的所有进程即其子进程，再进行删选即可。

实例
----------------------------------------

下面我们通过运行代码来感受一下PID namespace的隔离效果。修改上文的代码，加入PID namespace的标识位，
并把程序命名为pid.c。

```
    ...
    int child_pid = clone(child_main, child_stack + STACK_SIZE,
                          CLONE_NEWPID | CLONE_NEWIPC | CLONE_NEWUTS | SIGCHLD,
                          NULL);
    ...
```

编译运行可得如下结果:

```
$ sudo ./pid
[sudo] password for liminghao:
starting ...
in child
# echo $$ // 此处看到shell的pid变为了1
1
```

打印$$可以看到shell的PID，退出后如果再次执行可以看到效果如下:

```
# exit
exit
exited
$ echo $$
6930
```

已经回到了正常状态。可能有的读者在子进程的shell中执行了ps aux/top之类的命令，发现还是可以
看到所有父进程的PID，那是因为我们还没有对文件系统进行隔离，ps/top之类的命令调用的是真实系统下
的/proc文件内容，看到的自然是所有的进程。

PID namespace中的init进程
----------------------------------------

当我们新建一个PID namespace时，默认启动的进程PID为1。我们知道，在传统的UNIX系统中，PID为1的
进程是init，地位非常特殊。他作为所有进程的父进程，维护一张进程表，不断检查进程的状态，一旦有
某个子进程因为程序错误成为了“孤儿”进程，init就会负责回收资源并结束这个子进程。所以在你要实现
的容器中，启动的第一个进程也需要实现类似init的功能，维护所有后续启动进程的运行状态。

PID namespace维护这样一个树状结构，非常有利于系统的资源监控与回收。Docker启动时，第一个进程
也是这样，实现了进程监控和资源回收，它就是dockerinit。

信号与init进程
----------------------------------------

PID namespace中的init进程如此特殊，自然内核也为他赋予了特权——信号屏蔽。如果init中没有写处理
某个信号的代码逻辑，那么与init在同一个PID namespace下的进程（即使有超级权限）发送给它的该信号
都会被屏蔽。这个功能的主要作用是防止init进程被误杀。

那么其父节点PID namespace中的进程发送同样的信号会被忽略吗？父节点中的进程发送的信号，如果不是
SIGKILL（销毁进程）或SIGSTOP（暂停进程）也会被忽略。但如果发送SIGKILL或SIGSTOP，子节点的init会
强制执行（无法通过代码捕捉进行特殊处理），也就是说父节点中的进程有权终止子节点中的进程。

一旦init进程被销毁，同一PID namespace中的其他进程也会随之接收到SIGKILL信号而被销毁。理论上，
该PID namespace自然也就不复存在了。但是如果/proc/[pid]/ns/pid处于被挂载或者打开状态，
namespace就会被保留下来。然而，保留下来的namespace无法通过setns()或者fork()创建进程，
所以实际上并没有什么作用。

我们常说，Docker一旦启动就有进程在运行，不存在不包含任何进程的Docker，也就是这个道理。

挂载proc文件系统
----------------------------------------

如果你在新的PID namespace中使用ps命令查看，看到的还是所有的进程，因为与PID直接相关的/proc
文件系统（procfs）没有挂载到与原/proc不同的位置。所以如果你只想看到PID namespace本身应该
看到的进程，需要重新挂载/proc，命令如下。

```
# mount -t proc proc /proc
# ps -aux
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.1  0.0  27844  4776 pts/22   S    15:26   0:00 /bin/bash
root        14  0.0  0.0  22656  1304 pts/22   R+   15:26   0:00 ps -aux
```

可以看到实际的PID namespace就只有两个进程在运行。

**注意**: 因为此时我们没有进行mount namespace的隔离，所以这一步操作实际上已经影响了root namespace
的文件系统，当你退出新建的PID namespace以后再执行ps a就会发现出错，再次执行
mount -t proc proc /proc可以修复错误。

unshare()和setns()
----------------------------------------

在开篇我们就讲到了unshare()和setns()这两个API，而这两个API在PID namespace中使用时，也有一些特别
之处需要注意。

unshare()允许用户在原有进程中建立namespace进行隔离。但是创建了PID namespace后，原先unshare()
调用者进程并不进入新的PID namespace，接下来创建的子进程才会进入新的namespace，这个子进程也就
随之成为新namespace中的init进程。

类似的，调用setns()创建新PID namespace时，调用者进程也不进入新的PID namespace，而是随后创建的
子进程进入。

为什么创建其他namespace时unshare()和setns()会直接进入新的namespace而唯独PID namespace不是如此呢？

因为调用getpid()函数得到的PID是根据调用者所在的PID namespace而决定返回哪个PID，进入新的
PID namespace会导致PID产生变化。而对用户态的程序和库函数来说，他们都认为进程的PID是一个常量，
PID的变化会引起这些进程崩溃。

换句话说，一旦程序进程创建以后，那么它的PID namespace的关系就确定下来了，进程不会变更他们对应的
PID namespace。