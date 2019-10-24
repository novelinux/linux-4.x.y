## Fuse

### Fuse(Filesystem in Userspace)

早期的android系统没有使用fuse文件系统后来android为了控制不同APP对文件访问的权限，使用了fuse文件系统。早期手机内置SD卡使用一个独立vfat文件系统格式的分区。使用fuse之后，将手机内置SD卡与userdata分区合并成为一个分区。userdata分区使用ext4文件系统存储数据，访问userdata分区是直接操作ext4文件系统，而访问内置SD卡，则是先访问fuse文件系统，然后再访问ext4文件系统。

fuse文件系统的基本方法是，创建fuse设备，并将fuse设备挂载到与内置SD卡目录关联的目录。那么，对内置SD卡的访问变成了先访问fuse文件系统，再访问ext4文件系统。

fuse的内核部分创建了多个队列，其中包含一个pending队列和一个processing队列。每当有调用者对内置SD卡的系统调用时，fuse把文件访问路径转换为对ext4文件系统的操作路径，设置对应的操作码，并放入一个请求中。
fuse在用户态有3个监控线程，循环地读取fuse设备。对fuse设备的读取操作在内核部分转换从pending队列读取请求，如果队列中没有请求，则对应的线程进入睡眠状态。监控线程读取到pending队列中的请求后，把请求转换为对ext4文件系统的系统调用操作。系统调用执行完成后，监控线程把执行结果写入到fuse设备，对fuse设备的写操作在内核部分转换为把结果放入processing队列。processing队列依次取出结果，返回给调用者。

### Fuse访问文件流程

[Fuse](./fuse.webp)

图中体现了FUSE的2个关键部分（绿色方框），分别是Kernel中的那个FUSE(这里简称kernel FUSE)和user space中的那个fuse_user程序。其中kernel FUSE是负责把从用户层过来的文件系统操作请求传递给fuse_user程序的，而这个fuse_user程序实现了前面所说的文件系统的核心逻辑。
下面分步描述一下在用户对一个FUSE分区上的文件执行ls命令时发生了什么，当然，这里隐含了个前提，即这个系统的/tmp目录已经属于某个FUSE分区了，为了达到这种状况，前面还需要有一个mount的过程。

1.用户敲ls -l /tmp/file_on_fuse_fs+回车:这时ls会调用一些系统调用（例如stat(2)）。
2.kernel FUSE接收用户请求,文件相关的系统调用会进入VFS处理，然后VFS会根据这个分区的文件系统，找到对应文件系统的实现接口，这里当然是找到kernel FUSE。
3.kernel FUSE会把收到的操作请求按照FUSE定义的通信协议发送给fuse_user程序
4.fuse_user收到kernel FUSE发来的请求
5.fuse_user处理这个请求,这个“处理”完全是开发者自己定义的，只要符合开发者的要求就是合适的处理方式.


cat过程中的strace

```
root@android: # cd /sdcard
root@android:/sdcard # cat test.txt
root@android:/sdcard # strace -f -e open,openat,read,close cat test.txt
(..)
>>stripped output related to loading "cat" by shell<<
(..)                             = 0
openat(AT_FDCWD, "test.txt", O_RDONLY)  = 3
read(3, "1234\n", 1024)                 = 5
read(3, "", 1024)                       = 0
close(3)                                = 0
```

与此同时sdcard daemo 工作流程

```
  root@android: # ps | grep sdcard
  media_rw  714   1     23096  1528  ffffffff 81ca6254 S /system/bin/sdcard
  root@android: # strace -f -p 714
  Process 714 attached with 3 threads
  [pid   916] read(3,  <unfinished ...>
  [pid   915] read(3,  <unfinished ...>
  [pid   714] read(4,  <unfinished ...>
  [pid   916] <... read resumed> "1\0\0\0\1\0\0\0\2\234\3\0\0\0\0\0\200\200@\200\177\0\0\0\0\0\0\0\0\0\0\0"..., 262224) = 49
  [pid   916] faccessat(AT_FDCWD, "/data/media/0/test.txt", F_OK) = 0
  [pid   916] newfstatat(AT_FDCWD, "/data/media/0/test.txt", {st_mode=S_IFREG|0664, st_size=5, ...}, AT_SYMLINK_NOFOLLOW) = 0
  [pid   916] writev(3, [{"\220\0\0\0\0\0\0\0\2\234\3\0\0\0\0\0", 16}, {"\200\261\317\200\177\0\0\0\223(\0\0\0\0\0\0\n\0\0\0\0\0\0\0\n\0\0\0\0\0\0\0"..., 128}], 2) = 144
  [pid   915] <... read resumed> "0\0\0\0\16\0\0\0\3\234\3\0\0\0\0\0\200\261\317\200\177\0\0\0\0\0\0\0\0\0\0\0"..., 262224) = 48
  [pid   916] read(3,  <unfinished ...>
  [pid   915] openat(AT_FDCWD, "/data/media/0/test.txt", O_RDONLY|O_LARGEFILE) = 5
  [pid   915] writev(3, [{" \0\0\0\0\0\0\0\3\234\3\0\0\0\0\0", 16}, {"\260p\300\200\177\0\0\0\0\0\0\0\0\0\0\0", 16}], 2 <unfinished ...>
  [pid   916] <... read resumed> "P\0\0\0\17\0\0\0\4\234\3\0\0\0\0\0\200\261\317\200\177\0\0\0\0\0\0\0\0\0\0\0"..., 262224) = 80
  [pid   915] <... writev resumed> )      = 32
  [pid   916] pread64(5,  <unfinished ...>
  [pid   915] read(3,  <unfinished ...>
  [pid   916] <... pread64 resumed> "1234\n", 4096, 0) = 5
  [pid   916] writev(3, [{"\25\0\0\0\0\0\0\0\4\234\3\0\0\0\0\0", 16}, {"1234\n", 5}], 2) = 21
  [pid   915] <... read resumed> "8\0\0\0\3\0\0\0\5\234\3\0\0\0\0\0\200\261\317\200\177\0\0\0\0\0\0\0\0\0\0\0"..., 262224) = 56
  [pid   916] read(3,  <unfinished ...>
  [pid   915] newfstatat(AT_FDCWD, "/data/media/0/test.txt", {st_mode=S_IFREG|0664, st_size=5, ...}, AT_SYMLINK_NOFOLLOW) = 0
  [pid   915] writev(3, [{"x\0\0\0\0\0\0\0\5\234\3\0\0\0\0\0", 16}, {"\n\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\224(\0\0\0\0\0\0\5\0\0\0\0\0\0\0"..., 104}], 2) = 120
  [pid   916] <... read resumed> "@\0\0\0\31\0\0\0\6\234\3\0\0\0\0\0\200\261\317\200\177\0\0\0\0\0\0\0\0\0\0\0"..., 262224) = 64
  [pid   916] write(3, "\20\0\0\0\0\0\0\0\6\234\3\0\0\0\0\0", 16) = 16
  [pid   916] read(3, "@\0\0\0\22\0\0\0\7\234\3\0\0\0\0\0\200\261\317\200\177\0\0\0\0\0\0\0\0\0\0\0"..., 262224) = 64
  [pid   916] close(5)                    = 0
  [pid   916] write(3, "\20\0\0\0\0\0\0\0\7\234\3\0\0\0\0\0", 16) = 16
  [pid   916] read(3,  <unfinished ...>
  [pid   915] read(3, ^CProcess 714 detached
  Process 915 detached
```

注意关注进程号，其流程如下
* 1. userspace 程序的系统调用将由内核的Fuse驱动程序处理，即916进程
* 2. 内核中的Fuse驱动程序通知userspace守护进程(sdcard)有关新请求的信息
* 3. userspace守护进程读取 /dev/fuse
* 4. userspace守护进程解析命令并识别文件操作，如：open、read
* 5. userspace守护进程调用实际的底层文件系统，如EXT4、F2FS
* 6. 真实文件系统在内核处理请求并返回userspace
* 7. 如果userspace修改文件数据其将再次通过/dev/fuse/传递给内核
* 8. 内核完成底层真实文件系统调用并将数据移动到userspace的应用程序，如cat

由于Fuse有多次用户态和内核态切换这样势必会造成性能的损失，性能劣于真实文件系统。少量文件单次访问可能无法对比出差异，但当文件量增大就会产生质的变化。安卓应用在访问数据大部分都是以小文件居多，这样就会造成性能的损失，这也是为什么在android O上使用新的SDcardfs文件系统原因。下面用EXT4和Fuse对比

* 拷贝单个大文件对比

ext4:

```
root@android:/data # echo 3 > /proc/sys/vm/drop_caches //清除缓存，会释放pagecache、dentries、inodes缓存，这样就会直接反应真实文件系统性能
root@android:/data # dd if=bigbuck.in of=bigbuck.out bs=1m //bigbuck.in为data中存放的文件，同样也可以选择较大文件做对比测试
691+1 records in
691+1 records out
725106140 bytes transferred in 10.779 secs (67270260 bytes/sec)
```

fuse:

```
root@android:/sdcard # echo 3 > /proc/sys/vm/drop_caches
root@android:/sdcard # dd if=bigbuck.in of=bigbuck.out bs=1m
691+1 records in
691+1 records out
725106140 bytes transferred in 13.031 secs (55644704 bytes/sec)
```

* 小文件拷贝 10000个5kB文件

ext4:

```
root@android:/data # echo 3 > /proc/sys/vm/drop_caches
root@android:/data # time cp small/* small2/
  0m17.27s real     0m0.32s user     0m6.07s system
```

fuse:

```
root@android:/sdcard # echo 3 > /proc/sys/vm/drop_caches
root@android:/sdcard # time cp small/* small2/
  1m3.03s real     0m1.05s user     0m9.59s system
```