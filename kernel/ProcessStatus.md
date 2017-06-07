# Process Status

## D

Linux 进程的 Uninterruptible sleep(D) 状态

ps 的手册里说 D 状态是 uninterruptible sleep，Linux 进程有两种睡眠状态:

* 一种 interruptible sleep，处在这种睡眠状态的进程是可以通过给它发信号来唤醒的，
  比如发 HUP 信号给 nginx 的 master 进程可以让 nginx 重新加载配置文件而不需要重新启动 nginx 进程；
* 另外一种睡眠状态是 uninterruptible sleep，处在这种状态的进程不接受外来的任何信号，这也是为什么之前我无法用
  kill 杀掉这些处于 D 状态的进程，无论是 kill, kill -9 还是 kill -15，因为它们压根儿就不受这些信号的支配。

进程为什么会被置于 uninterruptible sleep 状态呢？处于 uninterruptible sleep 状态的进程通常是在等待 IO,
比如磁盘 IO，网络 IO，其他外设 IO，如果进程正在等待的 IO 在较长的时间内都没有响应，那么就很会不幸地被ps看到了，
同时也就意味着很有可能有 IO 出了问题，可能是外设本身出了故障，也可能是比如挂载的远程文件系统已经不可访问了，
我这里遇到的问题就是由 down 掉的 NFS 服务器引起的。

正是因为得不到 IO 的相应，进程才进入了 uninterruptible sleep 状态，所以要想使进程从 uninterruptible sleep
状态恢复，就得使进程等待的 IO 恢复，比如如果是因为从远程挂载的 NFS 卷不可访问导致进程进入 uninterruptible sleep 状态的，
那么可以通过恢复该 NFS 卷的连接来使进程的 IO 请求得到满足，除此之外，要想干掉处在 D 状态进程就只能重启整个 Linux 系统了。

看到有人说如果要想杀掉 D 状态的进程，通常可以去杀掉它的父进程（通常是 shell，我理解的这种情况是在 shell 下直接运行的该进程，
之后该进程转入了 D 状态），于是我就照做了，之后就出现了上面的状态：他们的父进程被杀掉了，但是他们的父进程 PID 都变成了1，
也就是 init 进程，这下可如何是好？此时我这些D状态的进程已经影响到其他一些进程的运行，而已经无法访问的 NFS 卷又在段时间内无法恢复，
那么，只好重新启动了，root 不是玉皇大帝，也有无奈的时候。

## Print D stack

```
# echo "D" > /proc/sysrq-trigger
# dmesg
```