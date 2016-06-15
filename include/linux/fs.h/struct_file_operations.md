struct file_operations
========================================

文件不能只存储信息，必须容许操作其中的信息。从用户的角度来看，
文件操作由标准库的函数执行。这些函数指示内核执行系统调用，然后
系统调用执行所需的操作。当然各个文件系统实现的接口可能不同。
因而VFS层提供了抽象的操作，以便将通用文件对象与具体文件系统
实现的底层机制关联起来。用于抽象文件操作的结构必须尽可能通用，
以考虑到各种各样的目标文件。同时，它不能带有过多只适用于特定
文件类型的专门操作。尽管如此，仍然必须满足各种文件（普通文件、
设备文件，等等）的特殊需求，以便充分利用。各个file实例都包含
一个指向struct file_operations实例的指针，该结构保存了指向所有
可能文件操作的函数指针。该结构定义如下：

path: include/linux/fs.h
```
struct file_operations {
    struct module *owner;
```

```
    loff_t (*llseek) (struct file *, loff_t, int);
```

read, write
----------------------------------------

```
    ssize_t (*read) (struct file *, char __user *, size_t, loff_t *);
    ssize_t (*write) (struct file *, const char __user *, size_t, loff_t *);
```

read和write分别负责读写数据。这两个函数的参数包括文件描述符、
缓冲区（放置读/写数据）和偏移量（指定在文件中读写数据的位置）。
另一个参数指定了需要读取和写入的字节数目。

```
    ssize_t (*read_iter) (struct kiocb *, struct iov_iter *);
    ssize_t (*write_iter) (struct kiocb *, struct iov_iter *);
    int (*iterate) (struct file *, struct dir_context *);
```

poll
----------------------------------------

```
    unsigned int (*poll) (struct file *, struct poll_table_struct *);
```

poll用于poll和select系统调用，以便实现同步的I/O多路复用。
这意味着什么？在进程等待来自文件对象的输入数据时，需要使用
read函数。如果没有数据可用（在进程从外部接口读取数据时，可能
有这样的情况），该调用将阻塞，直至数据可用。如果一直没有数据，
read函数将永远阻塞，这将导致不可接受的情况出现。

```
    long (*unlocked_ioctl) (struct file *, unsigned int, unsigned long);
    long (*compat_ioctl) (struct file *, unsigned int, unsigned long);
```

mmap
----------------------------------------

```
    int (*mmap) (struct file *, struct vm_area_struct *);
```

如果文件的内容映射到进程的虚拟地址空间中，访问文件就变得很容易。
这通过mmap完成.

open
----------------------------------------

```
    int (*open) (struct inode *, struct file *);
```

open打开一个文件，这相当于将一个file对象关联到一个inode。

flush
----------------------------------------

```
    int (*flush) (struct file *, fl_owner_t id);
```

在文件描述符关闭时将调用flush，同时将使用计数器减1，这一次计数器
不必是0（计数器为0时，将执行re-lease）。网络文件系统需要这个
函数，以标记传输结束。

release
----------------------------------------

```
    int (*release) (struct inode *, struct file *);
```

file对象的使用计数器到达0时，调用release。换句话说，即该文件
不再使用时。这使得底层实现能够释放不再需要的内存和缓存内容。

fsync
----------------------------------------

```
    int (*fsync) (struct file *, loff_t, loff_t, int datasync);
```

fsync由fsync和fdatasync系统调用使用，用于将内存中的文件数据与
存储介质同步。

aio_fsync
----------------------------------------

```
    int (*aio_fsync) (struct kiocb *, int datasync);
```

fasync
----------------------------------------

```
    int (*fasync) (int, struct file *, int);
```

fasync用于启用/停用由信号控制的输入和输出（通过信号通知进程
文件对象发生了改变）。

lock
----------------------------------------

```
    int (*lock) (struct file *, int, struct file_lock *);
```

lock函数用于锁定文件。它用于对多个进程的并发文件访问进行同步。

sendpage
----------------------------------------

```
    ssize_t (*sendpage) (struct file *, struct page *, int, size_t, loff_t *, int);
    unsigned long (*get_unmapped_area)(struct file *, unsigned long, unsigned long, unsigned long, unsigned long);
    int (*check_flags)(int);
    int (*flock) (struct file *, int, struct file_lock *);
    ssize_t (*splice_write)(struct pipe_inode_info *, struct file *, loff_t *, size_t, unsigned int);
    ssize_t (*splice_read)(struct file *, loff_t *, struct pipe_inode_info *, size_t, unsigned int);
    int (*setlease)(struct file *, long, struct file_lock **, void **);
    long (*fallocate)(struct file *file, int mode, loff_t offset,
              loff_t len);
    void (*show_fdinfo)(struct seq_file *m, struct file *f);
#ifndef CONFIG_MMU
    unsigned (*mmap_capabilities)(struct file *);
#endif
    ssize_t (*copy_file_range)(struct file *, loff_t, struct file *,
            loff_t, size_t, unsigned int);
    int (*clone_file_range)(struct file *, loff_t, struct file *, loff_t,
            u64);
    ssize_t (*dedupe_file_range)(struct file *, u64, u64, struct file *,
            u64);
};
```