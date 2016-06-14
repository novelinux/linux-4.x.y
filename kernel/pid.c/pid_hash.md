pid_hash
========================================

pid_hash用作一个hlist_head数组。数组的元素数目取决于计算机的内存配置，大约在24=16和212=4096之间。
pidhash_init用于计算恰当的容量并分配所需的内存。

path: kernel/pid.c
```
static struct hlist_head *pid_hash;
```