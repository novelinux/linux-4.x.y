## Java hs error

我们经常在部署Java服务的时候会发现因为内存不足导致部署服务无法正常启动，部署服务为啥不能正常启动呢？我们来探究一下这个原因
这种情况会将对应的的信息记录在hs_err_pid开头的log文件中，那么我们就通过分析下这个

```
#
# There is insufficient memory for the Java Runtime Environment to continue.
# Native memory allocation (mmap) failed to map 536870912 bytes for committing reserved memory.
# Possible reasons:
#   The system is out of physical RAM or swap space
#   In 32 bit mode, the process size limit was hit
# Possible solutions:
#   Reduce memory load on the system
#   Increase physical memory or swap space
#   Check if swap backing store is full
#   Use 64 bit Java on a 64 bit OS
#   Decrease Java heap size (-Xmx/-Xms)
#   Decrease number of Java threads
#   Decrease Java thread stack sizes (-Xss)
#   Set larger code cache with -XX:ReservedCodeCacheSize=
# This output file may be truncated or incomplete.
#
#  Out of Memory Error (os_linux.cpp:2640), pid=155435, tid=0x00007fdaf2db7700
#
# JRE version:  (8.0_131-b11) (build )
# Java VM: Java HotSpot(TM) 64-Bit Server VM (25.131-b11 mixed mode linux-amd64 compressed oops)
# Core dump written. Default location: /home/work/trace/core or core.155435
#


---------------  T H R E A D  ---------------

Current thread (0x00007fdaec018800):  JavaThread "Unknown thread" [_thread_in_vm, id=155455, stack(0x00007fdaf2d37000,0x00007fdaf2db8000)]

Stack: [0x00007fdaf2d37000,0x00007fdaf2db8000],  sp=0x00007fdaf2db5e10,  free space=507k
Native frames: (J=compiled Java code, j=interpreted, Vv=VM code, C=native code)
V  [libjvm.so+0xac826a]  VMError::report_and_die()+0x2ba
V  [libjvm.so+0x4fd4cb]  report_vm_out_of_memory(char const*, int, unsigned long, VMErrorType, char const*)+0x8b
V  [libjvm.so+0x924f53]  os::Linux::commit_memory_impl(char*, unsigned long, bool)+0x103
V  [libjvm.so+0x9253f5]  os::pd_commit_memory_or_exit(char*, unsigned long, unsigned long, bool, char const*)+0x35
V  [libjvm.so+0x91f3e6]  os::commit_memory_or_exit(char*, unsigned long, unsigned long, bool, char const*)+0x26
V  [libjvm.so+0x5c466f]  G1PageBasedVirtualSpace::commit_internal(unsigned long, unsigned long)+0xbf
V  [libjvm.so+0x5c48fc]  G1PageBasedVirtualSpace::commit(unsigned long, unsigned long)+0x11c
V  [libjvm.so+0x5c75e0]  G1RegionsLargerThanCommitSizeMapper::commit_regions(unsigned int, unsigned long)+0x40
V  [libjvm.so+0x62ac57]  HeapRegionManager::commit_regions(unsigned int, unsigned long)+0x77
V  [libjvm.so+0x62bef1]  HeapRegionManager::make_regions_available(unsigned int, unsigned int)+0x31
V  [libjvm.so+0x62c470]  HeapRegionManager::expand_by(unsigned int)+0xb0
V  [libjvm.so+0x59b7f9]  G1CollectedHeap::expand(unsigned long)+0x199
V  [libjvm.so+0x5a1af5]  G1CollectedHeap::initialize()+0x895
V  [libjvm.so+0xa902e3]  Universe::initialize_heap()+0xf3
V  [libjvm.so+0xa9084e]  universe_init()+0x3e
V  [libjvm.so+0x63e3e5]  init_globals()+0x65
V  [libjvm.so+0xa73f3e]  Threads::create_vm(JavaVMInitArgs*, bool*)+0x23e
V  [libjvm.so+0x6d2ce4]  JNI_CreateJavaVM+0x74
C  [libjli.so+0x745e]  JavaMain+0x9e
C  [libpthread.so.0+0x7dc5]  start_thread+0xc5
```

通过log我们很快能知道tid=155455的线程因为内存分配不足退出了导致整个进程退出
我先抬个杠？我们当前运行的进程是pid=155435，而退出的tid=155455的线程只是进程的一个线程而已，一个线程退出有什么无关紧要的，怎么就导致整个进程退出了呢？
我们先通过strace将整个进程启动的流程全部记录下来，来证明下究竟是不是这个线程退出导致的进程退出呢？

trace.155455

```
mmap(0xe0000000, 536870912, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_FIXED|MAP_ANONYMOUS, -1, 0) = -1 ENOMEM (Cannot allocate memory)
..
exit_group(1)                           = ?
+++ exited with 1 +++
```

我们很快可以回答我们刚才抬的杠，查看man手册

```
EXIT_GROUP(2)                                                                Linux Programmer's Manual                                                               EXIT_GROUP(2)

NAME
       exit_group - exit all threads in a process

SYNOPSIS
       #include <linux/unistd.h>

       void exit_group(int status);


DESCRIPTION
       This system call is equivalent to _exit(2) except that it terminates not only the calling thread, but all threads in the calling process's thread group.
```

exit_group是退出当前线程组所有线程，那么如何确认当前线程有没有和主线程在一个线程组呢？我们先看下主线程的trace:

trace.155435

```
...
clone(child_stack=0x7fdaf2db6fb0, flags=CLONE_VM|CLONE_FS|CLONE_FILES|CLONE_SIGHAND|CLONE_THREAD|CLONE_SYSVSEM|CLONE_SETTLS|CLONE_PARENT_SETTID|CLONE_CHILD_CLEARTID, parent_tidptr=0x7fdaf2db79d0, tls=0x7fdaf2db7700, child_tidptr=0x7fdaf2db79d0) = 155455
futex(0x7fdaf2db79d0, FUTEX_WAIT, 155455, NULL <unfinished ...>
+++ exited with 1 +++
```

CLONE_THREAD这个flag标记着当前退出线程是和主线程在同一个线程组.

```
CLONE_THREAD (since Linux 2.4.0-test8)
              If CLONE_THREAD is set, the child is placed in the same thread group as the calling process.  To make the remainder of the discussion of CLONE_THREAD more readable,
              the term "thread" is used to refer to the processes within a thread group.

              Thread groups were a feature added in Linux 2.4 to support the POSIX threads notion of a set of threads that share a single PID.  Internally, this shared PID is the
              so-called thread group identifier (TGID) for the thread group.  Since Linux 2.4, calls to getpid(2) return the TGID of the caller.

              The threads within a group can be distinguished by their (system-wide) unique thread IDs (TID).  A new thread's TID is available as the function result returned  to
              the caller of clone(), and a thread can obtain its own TID using gettid(2).

              When  a  call  is  made to clone() without specifying CLONE_THREAD, then the resulting thread is placed in a new thread group whose TGID is the same as the thread's
              TID.  This thread is the leader of the new thread group.

              A new thread created with CLONE_THREAD has the same parent process as the caller of clone() (i.e., like CLONE_PARENT), so that calls to getppid(2) return  the  same
              value  for  all  of  the threads in a thread group.  When a CLONE_THREAD thread terminates, the thread that created it using clone() is not sent a SIGCHLD (or other
              termination) signal; nor can the status of such a thread be obtained using wait(2).  (The thread is said to be detached.)

              After all of the threads in a thread group terminate the parent process of the thread group is sent a SIGCHLD (or other termination) signal.

              If any of the threads in a thread group performs an execve(2), then all threads other than the thread group leader are terminated, and the new program  is  executed
              in the thread group leader.

              If one of the threads in a thread group creates a child using fork(2), then any thread in the group can wait(2) for that child.

              Since Linux 2.5.35, flags must also include CLONE_SIGHAND if CLONE_THREAD is specified (and note that, since Linux 2.6.0-test6, CLONE_SIGHAND also requires CLONE_VM
              to be included).

              Signals may be sent to a thread group as a whole (i.e., a TGID) using kill(2), or to a specific thread (i.e., TID) using tgkill(2).

              Signal dispositions and actions are process-wide: if an unhandled signal is delivered to a thread, then it will affect (terminate, stop, continue,  be  ignored  in)
              all members of the thread group.

              Each  thread  has  its  own  signal mask, as set by sigprocmask(2), but signals can be pending either: for the whole process (i.e., deliverable to any member of the
              thread group), when sent with kill(2); or for an individual thread, when sent with tgkill(2).  A call to sigpending(2) returns a signal set that is the union of the
              signals pending for the whole process and the signals that are pending for the calling thread.

              If kill(2) is used to send a signal to a thread group, and the thread group has installed a handler for the signal, then the handler will be invoked in exactly one,
              arbitrarily selected member of the thread group that has not blocked the signal.  If multiple threads in a group are waiting to accept the same  signal  using  sig‐
              waitinfo(2), the kernel will arbitrarily select one of these threads to receive a signal sent using kill(2).
```

我们回到正题继续分析线程155455的堆栈

```
Stack: [0x00007fdaf2d37000,0x00007fdaf2db8000],  sp=0x00007fdaf2db5e10,  free space=507k
Native frames: (J=compiled Java code, j=interpreted, Vv=VM code, C=native code)
V  [libjvm.so+0xac826a]  VMError::report_and_die()+0x2ba
V  [libjvm.so+0x4fd4cb]  report_vm_out_of_memory(char const*, int, unsigned long, VMErrorType, char const*)+0x8b
V  [libjvm.so+0x924f53]  os::Linux::commit_memory_impl(char*, unsigned long, bool)+0x103
V  [libjvm.so+0x9253f5]  os::pd_commit_memory_or_exit(char*, unsigned long, unsigned long, bool, char const*)+0x35
V  [libjvm.so+0x91f3e6]  os::commit_memory_or_exit(char*, unsigned long, unsigned long, bool, char const*)+0x26
V  [libjvm.so+0x5c466f]  G1PageBasedVirtualSpace::commit_internal(unsigned long, unsigned long)+0xbf
V  [libjvm.so+0x5c48fc]  G1PageBasedVirtualSpace::commit(unsigned long, unsigned long)+0x11c
V  [libjvm.so+0x5c75e0]  G1RegionsLargerThanCommitSizeMapper::commit_regions(unsigned int, unsigned long)+0x40
V  [libjvm.so+0x62ac57]  HeapRegionManager::commit_regions(unsigned int, unsigned long)+0x77
V  [libjvm.so+0x62bef1]  HeapRegionManager::make_regions_available(unsigned int, unsigned int)+0x31
V  [libjvm.so+0x62c470]  HeapRegionManager::expand_by(unsigned int)+0xb0
V  [libjvm.so+0x59b7f9]  G1CollectedHeap::expand(unsigned long)+0x199
V  [libjvm.so+0x5a1af5]  G1CollectedHeap::initialize()+0x895
V  [libjvm.so+0xa902e3]  Universe::initialize_heap()+0xf3
V  [libjvm.so+0xa9084e]  universe_init()+0x3e
V  [libjvm.so+0x63e3e5]  init_globals()+0x65
V  [libjvm.so+0xa73f3e]  Threads::create_vm(JavaVMInitArgs*, bool*)+0x23e
V  [libjvm.so+0x6d2ce4]  JNI_CreateJavaVM+0x74
C  [libjli.so+0x745e]  JavaMain+0x9e
C  [libpthread.so.0+0x7dc5]  start_thread+0xc5
```

整个堆栈是创建Java虚拟机的时候初始化heap，为heap分配内存的时候失败了，通过hs_err log我们得知想要分配536870912(512MB)字节的内存不足，导致线程退出，我们看下我们跟堆内存大小相关的JVM配置参数．

```
app.jvm.onebox=" -Xms512M -Xmx512M -Xmn256M -XX:MaxDirectMemorySize=128M " ${app.jvm.base}
```

具体字段的含义如下：

* -Xms	初始堆大小
* -Xmx	最大堆大小
* -Xmn   年轻代大小,整个堆大小=年轻代大小 + 年老代大小 + 持久代大小.

根据代码堆栈分析我们推测这是分配初始堆内存，为了验证推测我们将-Xms参数调整为256M，于是，报了如下的错误，现在变成了分配256M的内存失败（为了解决这个问题我们可以将-Xms调整为128M，此时服务正常启动）

```
$ /bin/bash /home/work/app/MiotDungBeetleManager/bin/MiotDungBeetleManagerCtrl.sh -r
JAVA_OPTS=-Dconfig.resource=application-onebox.conf -Dlog4j.debug
EXTRA_JVM_ARGUMENTS=-Xms256M -Xmx512M -Xmn256M -XX:MaxDirectMemorySize=128M -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -Xss512K -XX:+UseCompressedOops -XX:+PrintReferenceGC -XX:+PrintGCDetails -XX:+PrintGCDateStamps -XX:+PrintHeapAtGC -XX:+PrintGCApplicationStoppedTime -XX:+PrintPromotionFailure -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=100 -XX:GCLogFileSize=128M -verbose:gc -Xloggc:/home/work/data/soft/MiotDungBeetleManager/logs/gc-20190411215606.log
Java HotSpot(TM) 64-Bit Server VM warning: INFO: os::commit_memory(0x00000000e0000000, 268435456, 0) failed; error='Cannot allocate memory' (errno=12)
#
# There is insufficient memory for the Java Runtime Environment to continue.
# Native memory allocation (mmap) failed to map 268435456 bytes for committing reserved memory.
# An error report file with more information is saved as:
# /home/work/liminghao/trace/hs_err_pid132876.log
```

我们接着向下分析这个问题，直接看Java虚拟机源码查看commit_memory_impl函数，分析是怎么分配JVM初始堆内存大小的

```
// NOTE: Linux kernel does not really reserve the pages for us.
//       All it does is to check if there are enough free pages
//       left at the time of mmap(). This could be a potential
//       problem.
int os::Linux::commit_memory_impl(char* addr, size_t size, bool exec) {
  int prot = exec ? PROT_READ|PROT_WRITE|PROT_EXEC : PROT_READ|PROT_WRITE;
  uintptr_t res = (uintptr_t) ::mmap(addr, size, prot,
                                   MAP_PRIVATE|MAP_FIXED|MAP_ANONYMOUS, -1, 0);
  if (res != (uintptr_t) MAP_FAILED) {
    if (UseNUMAInterleaving) {
      numa_make_global(addr, size);
    }
    return 0;
  }

  int err = errno;  // save errno from mmap() call above

  if (!recoverable_mmap_error(err)) {
    warn_fail_commit_memory(addr, size, exec, err);
    vm_exit_out_of_memory(size, OOM_MMAP_ERROR, "committing reserved memory.");
  }

  return err;
}
```

通过源码我们得知是通过mmap函数来分配内存，
mmap的功能：

```
DESCRIPTION
       mmap()  creates  a  new  mapping  in the virtual address space of the calling process.  The starting address for the new mapping is specified in addr.  The length argument
       specifies the length of the mapping (which must be greater than 0).

       If addr is NULL, then the kernel chooses the address at which to create the mapping; this is the most portable method of creating a new mapping.  If addr is not NULL, then
       the  kernel  takes  it  as  a  hint  about  where to place the mapping; on Linux, the mapping will be created at a nearby page boundary.  The address of the new mapping is
       returned as the result of the call.

       The contents of a file mapping (as opposed to an anonymous mapping; see MAP_ANONYMOUS below), are initialized using length bytes starting at offset offset in the file  (or
       other object) referred to by the file descriptor fd.  offset must be a multiple of the page size as returned by sysconf(_SC_PAGE_SIZE).
```

从man手册得知mmap函数的作用是从当前进程的虚拟地址空间中分配一段mapping空间出来

我们首先了解下进程虚拟地址空间：用户层进程的虚拟地址空间是Linux的一个重要抽象： 它向每个运行进程提供了同样的系统视图，这使得多个进程可以同时 运行，而不会干扰到其他进程内存中的内容。
•　每个应用程序都有自身的地址空间，与所有其他应用程序分隔开。
•　通常在巨大的线性地址空间中，只有很少的段可用于各个用户空间进程，这些段彼此有一定的距离。内核需要一些数据结构，来有效地管理这些（随机）分布的段。
•　地址空间只有极小的一部分与物理内存页直接关联。不经常使用的部分，则仅当必要时与页帧关联。
各个进程的虚拟地址空间起始于地址0，延伸到TASK_SIZE- 1，其上是内核地址空间。在IA-32系统上地址空间的范围可达2＾32 = 4 GiB，总的地址空间通常按3:1比例划分。内核分配了1 GiB，而各个用户空间进程可用的部分为3 GiB；AMD64 和 ARMv8 可以支持 2^64 次方的地址空间，这可是个相当大的数字。实际上，2^64 次方太大了，Linux 内核只采用了 64 bits 的一部分，假设VA_BITS = 39,  64位机器上也有足够的虚拟地址了，用户空间和内核空间可以有各自的 2^39 = 512GB 的虚拟地址。
所有用户虚拟地址前25bits均为0，所有的内核虚拟地址前25bits均为 1。用户与内核之间的地址不可使用。
内存虚拟地址空间的布局

1.经典布局

https://github.com/novelinux/linux-4.x.y/tree/master/mm/mmap.c/res/old_layout.jpg

如果计算机提供了巨大的虚拟地址空间，那么使用上述的地址空间布局 会工作得非常好。但在32位计算机上可能会出问题. 对于每个用户进程 其虚拟地址空间从0到0xc0000000,有3GB可用. TASK_UNMAPPED_BASE 起始于0x40000000, 即1GB处.糟糕的是，堆只有1GB空间可用继续增长 会进入到mmap区域. 问题在于内存映射区域位于虚拟地址空间中间. 从2.6.7引入了一个新的虚拟地址空间布局.

2.新布局

https://github.com/novelinux/linux-4.x.y/tree/master/mm/mmap.c/res/new_layout.jpg

其目的在于使用固定值限制栈的最大长度. 由于栈是有界的，因此安置内存映射的区域可以在栈末端的下方开始.与经典方法相反，改区域现在 是自顶向下扩展。由于堆仍然位于虚拟地址空间中较低的区域并向上增长，

因此mmap区域和堆区域可以相对扩展，直至耗尽虚拟地址空间中 剩余的区域。为确保栈和mmap区域不发生冲突，在两者之间设置一个安全间隙.

我们看下我们使用的是哪种布局呢？

```
[work@tj1-smart-onebox04 /proc/sys/vm]$ cat legacy_va_layout
0
```

1表示使用经典布局；0表示使用新的布局:

疑问：一个用户态的进程既然有那么大的虚拟地址空间，怎么分配一个小小的512MB空间都分配不出来呢？

为了验证这个问题我们写一个段测试代码来验证：

```
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>

int main(int argc, char *argv[])
{

  int i = 0;
  uint64_t start_addr = 0x7f2000000000;
  uint64_t size = atoi(argv[1]) * 1024 * 1024;

  for (i = 0; i < atoi(argv[2]); ++i) {
    int prot = PROT_READ|PROT_WRITE;
    uintptr_t res = (uintptr_t)mmap(start_addr, size, prot, MAP_PRIVATE|MAP_FIXED|MAP_ANONYMOUS,
				    -1, 0);

    if (res == (uintptr_t)-1) {
      perror("mmap error");
      break;
    } else {
      printf("res=0x%lX\n", res);
    }
    start_addr += size;
  }

  while (1) {
    sleep(1000);
  }

  return 0;
}
```

* 验证一：一次性分配512MB内存：

```
[work@tj1-smart-onebox04 ~/liminghao]$ ./a.out 512 1
mmap error: Cannot allocate memory
```

* 验证二：分两次，每次分配256MB内存：

```
[work@tj1-smart-onebox04 ~/liminghao]$ ./a.out 256 2
res=0x7F2000000000
res=0x7F2010000000
```

通过两次验证我们发现：一次分配512MB内存失败，确实当前内存不足；但是第二次的验证结果就非常有意思了，我分两次分配内存成功了，而且这两块内存是连续的。
我们再次回到我们这个疑问：一个用户态的进程既然有那么大的虚拟地址空间，怎么分配一个小小的512MB空间都分配不出来呢？
事实上：一次性分配512MB内存，确实分配不出来，但是分两次就分配出来了。

推测：内核对一次性分配的虚拟内存大小有限制。

查看内核源码：

```
path: mm/util.c
/*
 * Check that a process has enough memory to allocate a new virtual
 * mapping. 0 means there is enough memory for the allocation to
 * succeed and -ENOMEM implies there is not.
 *
 * We currently support three overcommit policies, which are set via the
 * vm.overcommit_memory sysctl.  See Documentation/vm/overcommit-accounting.rst
 *
 * Strict overcommit modes added 2002 Feb 26 by Alan Cox.
 * Additional code 2002 Jul 20 by Robert Love.
 *
 * cap_sys_admin is 1 if the process has admin privileges, 0 otherwise.
 *
 * Note this is a helper function intended to be used by LSMs which
 * wish to use this logic.
 */
int __vm_enough_memory(struct mm_struct *mm, long pages, int cap_sys_admin)
{
	long free, allowed, reserve;

	VM_WARN_ONCE(percpu_counter_read(&vm_committed_as) <
			-(s64)vm_committed_as_batch * num_online_cpus(),
			"memory commitment underflow");

	vm_acct_memory(pages);

	/*
	 * Sometimes we want to use more memory than we have
	 */
	if (sysctl_overcommit_memory == OVERCOMMIT_ALWAYS)
		return 0;

	if (sysctl_overcommit_memory == OVERCOMMIT_GUESS) {
		free = global_zone_page_state(NR_FREE_PAGES);
		free += global_node_page_state(NR_FILE_PAGES);

		/*
		 * shmem pages shouldn't be counted as free in this
		 * case, they can't be purged, only swapped out, and
		 * that won't affect the overall amount of available
		 * memory in the system.
		 */
		free -= global_node_page_state(NR_SHMEM);

		free += get_nr_swap_pages();

		/*
		 * Any slabs which are created with the
		 * SLAB_RECLAIM_ACCOUNT flag claim to have contents
		 * which are reclaimable, under pressure.  The dentry
		 * cache and most inode caches should fall into this
		 */
		free += global_node_page_state(NR_SLAB_RECLAIMABLE);

		/*
		 * Part of the kernel memory, which can be released
		 * under memory pressure.
		 */
		free += global_node_page_state(NR_KERNEL_MISC_RECLAIMABLE);

		/*
		 * Leave reserved pages. The pages are not for anonymous pages.
		 */
		if (free <= totalreserve_pages)
			goto error;
		else
			free -= totalreserve_pages;

		/*
		 * Reserve some for root
		 */
		if (!cap_sys_admin)
			free -= sysctl_admin_reserve_kbytes >> (PAGE_SHIFT - 10);

		if (free > pages)
			return 0;

		goto error;
	}

	allowed = vm_commit_limit();
	/*
	 * Reserve some for root
	 */
	if (!cap_sys_admin)
		allowed -= sysctl_admin_reserve_kbytes >> (PAGE_SHIFT - 10);

	/*
	 * Don't let a single process grow so big a user can't recover
	 */
	if (mm) {
		reserve = sysctl_user_reserve_kbytes >> (PAGE_SHIFT - 10);
		allowed -= min_t(long, mm->total_vm / 32, reserve);
	}

	if (percpu_counter_read_positive(&vm_committed_as) < allowed)
		return 0;
error:
	vm_unacct_memory(pages);

	return -ENOMEM;
}
```

这种限制一次性分配虚拟内存大小的机制是：MEMORY OVERCOMMIT（内存过量使用机制）
Memory Overcommit的意思是操作系统承诺给进程的内存大小超过了实际可用的内存。一个保守的操作系统不会允许memory overcommit， 有多少就分配多少，再申请就没有了，这其实有些浪费内存，因为进程实际使用到的内存往往比申请的内存要少，比如某个进程malloc(最终实现也是调用mmap)了200MB内存， 但实际上只用到了100MB，按照Linux的算法，物理内存页的分配发生在使用的瞬间，而不是在申请的瞬间，也就是说未用到的100MB内存根本就没有分配， 这100MB内存就闲置了。

下面这个概念很重要，是理解memory overcommit的关键：overcommit针对的是内存申请，内存申请不等于内存分配，内存只在实际用到的时候才分配。

Linux是允许memory overcommit的，只要你来申请内存我就给你，寄希望于进程实际上用不到那么多内存，但万一用到那么多了呢？那就会发生类似“银行挤兑”的危机， 现金(物理内存)不足了。Linux设计了一个OOM killer机制(OOM = out-of-memory)来处理这种危机：挑选一个进程出来杀死，以腾出部分内存，如果还不够就继续杀… 也可通过设置内核参数 vm.panic_on_oom 使得发生OOM时自动重启系统。这都是有风险的机制，重启有可能造成业务中断，杀死进程也有可能导致业务中断， 所以Linux 2.6之后允许通过内核参数 vm.overcommit_memory 禁止memory overcommit。

内核参数 vm.overcommit_memory 接受三种取值：

* 0 – Heuristic(启发式的) overcommit handling. 这是缺省值，它允许overcommit，但过于明目张胆的overcommit会被拒绝， 比如malloc一次性申请的内存大小就超过了系统总内存。Heuristic的意思是“试探式的”，内核利用某种算法（对该算法的详细解释请看文末） 猜测你的内存申请是否合理，它认为不合理就会拒绝overcommit。
* 1 – Always overcommit. 允许overcommit，对内存申请来者不拒。
* 2 – Don’t overcommit. 禁止overcommit。关于禁止overcommit (vm.overcommit_memory=2) ，需要知道的是，怎样才算是overcommit呢？ kernel设有一个阈值，申请的内存总数超过这个阈值就算overcommit，在/proc/meminfo中可以看到这个阈值的大小：

```
[work@tj1-smart-onebox04 /proc/sys/vm]$ cat /proc/meminfo | grep -i commit
CommitLimit:     2023388 kB
Committed_AS:   10014688 kB
```

我们看下我们服务器的配置（以onebox为例）：

```
[work@tj1-smart-onebox04 /proc/sys/vm]$ cat overcommit_memory
0
```

我们服务器默认的配置是利用Heuristic算法来猜测我们这次分配的内存是否合理，不合理的话就会拒绝。我们可以这样简单的理解这种算法：
**单次申请的内存大小不能超过 【free memory + free swap + pagecache的大小 + SLAB中可回收的部分】，否则本次申请就会失败。**
查看当前物理内存

```
[work@tj1-smart-onebox04 ~/]$ free -m
              total        used        free      shared  buff/cache   available
Mem:           3951        3352         142         202         456         170
Swap:             0           0           0
```

看下free命令中各个列的解释：

```
DESCRIPTION
       free  displays  the total amount of free and used physical and swap memory in the system, as well as the buffers and caches used by the kernel. The information is gathered
       by parsing /proc/meminfo. The displayed columns are:

       total  Total installed memory (MemTotal and SwapTotal in /proc/meminfo)

       used   Used memory (calculated as total - free - buffers - cache)

       free   Unused memory (MemFree and SwapFree in /proc/meminfo)

       shared Memory used (mostly) by tmpfs (Shmem in /proc/meminfo)

       buffers
              Memory used by kernel buffers (Buffers in /proc/meminfo)

       cache  Memory used by the page cache and slabs (Cached and SReclaimable in /proc/meminfo)

       buff/cache
              Sum of buffers and cache

       available
              Estimation of how much memory is available for starting new applications, without swapping. Unlike the data provided by the cache or free fields, this  field  takes
              into account page cache and also that not all reclaimable memory slabs will be reclaimed due to items being in use (MemAvailable in /proc/meminfo, available on ker‐
              nels 3.14, emulated on kernels 2.6.27+, otherwise the same as free)
```

我们知道used + free + buff 基本等于 total
* used是被使用的
* free是完全没有被使用的
* shared是被程序之间可以(已经被)共享使用的
* buffers是指用来给块设备做的缓冲大小；
* cached是用来给文件做缓冲
* buffers是用来存储目录里面有什么内容，权限等等。而cached直接用来缓存我们打开的文件
* available这才是"可用内存" , 而不是像过去那样简单的把free和buffer加起来

综上分析这就解释了为什么我们分配虚拟的是虚拟内存最终却会由于物理内存不够导致分配内存失败。


参考：

mmap原理详细分析：https://github.com/novelinux/linux-4.x.y/tree/master/mm/mmap.c