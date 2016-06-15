struct files_struct
========================================

count
----------------------------------------

path: include/linux/fdtable.h
```
/*
 * Open file table structure
 */
struct files_struct {
  /*
   * read mostly part
   */
    atomic_t count;
```

resize_in_progress
----------------------------------------

```
    bool resize_in_progress;
    wait_queue_head_t resize_wait;
```

fdt, fdtab
----------------------------------------

```
    struct fdtable __rcu *fdt;
    struct fdtable fdtab;
```

struct files_struct中包含了struct fdtable结构的一个实例和指向一个实例的指针，因为这里使用了
RCU机制以便在无需锁定的情况下读取这些数据结构，这可以加速处理.

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/fdtable.h/struct_fdtable.md

**注意**:

初看起来，struct fdtable和struct files_struct之间某些信息似乎是重复的：
exec时关闭文件描述符和打开文件描述符两个位图，以及file指针的数组。事实上并非如此，因为
files_struct中的成员是数据结构真正的实例，而fdtable的成员则是指针。实际上，后者的成员
fd、open_fds和close_on_exec都初始化为指向前者对应的3个成员。因此，fd数组包含了NR_OPEN_DEFAULT项。
close_on_exec和open_fds位图最初包括BITS_PER_LONG个比特位。由于NR_OPEN_DEFAULT设置为BITS_PER_LONG，
所有这些长度都是相同的。如果需要打开更多文件，内核会分配一个fd_set的实例.

如果两个位图或fd数组的初始长度限制太低，内核可以将对应的指针指向更大的结构，以扩展空间。
数组扩展的“步长”是不同的，这也说明了为什么该结构中描述符和文件数量需要两个不同的最大值。

____cacheline_aligned_in_smp
----------------------------------------

```
   /*
    * written part on a separate cache line in SMP
    */
    spinlock_t file_lock ____cacheline_aligned_in_smp;
```

next_fd
----------------------------------------

```
    int next_fd;
```

next_fd表示下一次打开新文件时使用的文件描述符。

close_on_exec_init
----------------------------------------

```
    unsigned long close_on_exec_init[1];
```

close_on_exec_init是位图, 对执行exec时将关闭的所有文件描述符，
在close_on_exec中对应的比特位都将置位。

open_fds_init
----------------------------------------

```
    unsigned long open_fds_init[1];
```

open_fds_init是位图, open_fds_init是最初的文件描述符集合。

fd_array
----------------------------------------

```
    struct file __rcu * fd_array[NR_OPEN_DEFAULT];
};
```

fd_array的每个数组项都是一个指针，指向每个打开文件的struct file实例.
默认情况下，内核允许每个进程打开NR_OPEN_DEFAULT个文件。

### NR_OPEN_DEFAULT

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/fdtable.h/NR_OPEN_DEFAULT.md

### struct file

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/fs.h/struct_file.md
