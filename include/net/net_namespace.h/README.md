Net Namespace
========================================

Network namespace主要提供了关于网络资源的隔离，包括网络设备、IPv4和IPv6协议栈、IP路由表、防火墙、
/proc/net目录、/sys/class/net目录、端口（socket）等等。一个物理的网络设备最多存在在一个
network namespace中，你可以通过创建veth pair（虚拟网络设备对：有两端，类似管道，如果数据从一端
传入另一端也能接收到，反之亦然）在不同的network namespace间创建通道，以此达到通信的目的。

一般情况下，物理网络设备都分配在最初的root namespace（表示系统默认的namespace，在PID namespace
中已经提及）中。但是如果你有多块物理网卡，也可以把其中一块或多块分配给新创建的network namespace。
需要注意的是，当新创建的network namespace被释放时（所有内部的进程都终止并且namespace文件没有被
挂载或打开），在这个namespace中的物理网卡会返回到root namespace而非创建该进程的父进程所在的
network namespace.

当我们说到network namespace时，其实我们指的未必是真正的网络隔离，而是把网络独立出来，给
外部用户一种透明的感觉，仿佛跟另外一个网络实体在进行通信。为了达到这个目的，容器的经典做法
就是创建一个veth pair，一端放置在新的namespace中，通常命名为eth0，一端放在原先的namespace中
连接物理网络设备，再通过网桥把别的设备连接进来或者进行路由转发，以此网络实现通信的目的。

在建立起veth pair之前，新旧namespace该如何通信呢？

答案是pipe（管道）。我们以Docker Daemon在启动容器dockerinit的过程为例。Docker Daemon在宿主机上
负责创建这个veth pair，通过netlink调用，把一端绑定到docker0网桥上，一端连进新建的
network namespace进程中。建立的过程中，Docker Daemon和dockerinit就通过pipe进行通信，
当Docker Daemon完成veth-pair的创建之前，dockerinit在管道的另一端循环等待，直到管道另一端传来
Docker Daemon关于veth设备的信息，并关闭管道。dockerinit才结束等待的过程，并把它的“eth0”启动起来。

Data Structure
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/include/net/net_namespace.h/struct_net.md

init_net
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/net/core/net_namespace.c/init_net.md

Sample
----------------------------------------

跟其他namespace类似，对network namespace的使用其实就是在创建的时候添加CLONE_NEWNET标识位。
也可以通过命令行工具ip创建network namespace。在代码中建立和测试network namespace较为复杂，
所以下文主要通过ip命令直观的感受整个network namespace网络建立和配置的过程。

首先我们可以创建一个命名为test_ns的network namespace。

```
# ip netns add test_ns
```

当ip命令工具创建一个network namespace时，会默认创建一个回环设备（loopback interface：lo），
并在/var/run/netns目录下绑定一个挂载点，这就保证了就算network namespace中没有进程在运行也不会
被释放，也给系统管理员对新创建的network namespace进行配置提供了充足的时间。

通过ip netns exec命令可以在新创建的network namespace下运行网络管理命令。

```
# ip netns exec test_ns ip link list
1: lo: <LOOPBACK> mtu 65536 qdisc noop state DOWN mode DEFAULT group default
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
```

上面的命令为我们展示了新建的namespace下可见的网络链接，可以看到状态是DOWN,需要再通过命令去启动。
可以看到，此时执行ping命令是无效的。

```
# ip netns exec test_ns ping 127.0.0.1
connect: Network is unreachable
```

启动命令如下，可以看到启动后再测试就可以ping通。

```
# ip netns exec test_ns ip link set dev lo up
# ip netns exec test_ns ping 127.0.0.1
PING 127.0.0.1 (127.0.0.1) 56(84) bytes of data.
64 bytes from 127.0.0.1: icmp_req=1 ttl=64 time=0.050 ms
...
```

这样只是启动了本地的回环，要实现与外部namespace进行通信还需要再建一个网络设备对，命令如下。

```
# ip link add veth0 type veth peer name veth1
# ip link set veth1 netns test_ns
# ip netns exec test_ns ifconfig veth1 10.1.1.1/24 up
# ifconfig veth0 10.1.1.2/24 up
```

第一条命令创建了一个网络设备对，所有发送到veth0的包veth1也能接收到，反之亦然。
第二条命令则是把veth1这一端分配到test_ns这个network namespace。
第三、第四条命令分别给test_ns内部和外部的网络设备配置IP，veth1的IP为10.1.1.1，veth0的IP为10.1.1.2.
此时两边就可以互相连通了，效果如下:

```
# ping 10.1.1.1
PING 10.1.1.1 (10.1.1.1) 56(84) bytes of data.
64 bytes from 10.1.1.1: icmp_req=1 ttl=64 time=0.095 ms
...
# ip netns exec test_ns ping 10.1.1.2
PING 10.1.1.2 (10.1.1.2) 56(84) bytes of data.
64 bytes from 10.1.1.2: icmp_req=1 ttl=64 time=0.049 ms
...
```

读者有兴趣可以通过下面的命令查看，新的test_ns有着自己独立的路由和iptables。

```
ip netns exec test_ns route
ip netns exec test_ns iptables -L
```

路由表中只有一条通向10.1.1.2的规则，此时如果要连接外网肯定是不可能的，你可以通过建立网桥或者
NAT映射来决定这个问题。如果你对此非常感兴趣，可以阅读Docker网络相关文章进行更深入的讲解。
做完这些实验，你还可以通过下面的命令删除这个network namespace。

```
# ip netns delete test_ns
```

这条命令会移除之前的挂载，但是如果namespace本身还有进程运行，namespace还会存在下去，直到进程运行
结束。

通过network namespace我们可以了解到，实际上内核创建了network namespace以后，真的是得到了一个被
隔离的网络。但是我们实际上需要的不是这种完全的隔离，而是一个对用户来说透明独立的网络实体，
我们需要与这个实体通信。