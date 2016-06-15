struct fs_struct
========================================

除了打开文件描述符的列表之外，还必须管理其他特定于进程的数据。
因而每个task_struct实例都包含一个指针，指向另一个结构，类型为
fs_struct。

path: include/linux/fs_struct.h
```
struct fs_struct {
    int users;
    spinlock_t lock;
    seqcount_t seq;
```

umask
----------------------------------------

```
    int umask;
```

umask表示标准的掩码，用于设置新文件的权限。其值可以使用umask
命令读取或设置。在内部由同名的系统调用完成。

in_exec
----------------------------------------

```
    int in_exec;
```

root, pwd
----------------------------------------

```
    struct path root, pwd;
};
```

root指定了相关进程的根目录和文件系统。当然，对于通过chroot
（暗中通过同名的系统调用）锁定到某个子目录的进程来说，情况
并非如此。那么相应的进程就会使用某个子目录，而不是全局的根目录，
该进程会将该子目录视为其根目录。

pwd指定了当前工作目录和文件系统的vfsmount结构。在进程改变其
当前目录时，二者都会动态改变。

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/path.h/struct_path.md
