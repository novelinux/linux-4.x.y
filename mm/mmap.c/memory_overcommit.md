## 理解LINUX的MEMORY OVERCOMMIT

Memory Overcommit的意思是操作系统承诺给进程的内存大小超过了实际可用的内存。一个保守的操作系统不会允许memory overcommit，
有多少就分配多少，再申请就没有了，这其实有些浪费内存，因为进程实际使用到的内存往往比申请的内存要少，比如某个进程malloc()了200MB内存，
但实际上只用到了100MB，按照UNIX/Linux的算法，物理内存页的分配发生在使用的瞬间，而不是在申请的瞬间，也就是说未用到的100MB内存根本就没有分配，
这100MB内存就闲置了。

下面这个概念很重要，是理解memory overcommit的关键：commit(或overcommit)针对的是内存申请，内存申请不等于内存分配，内存只在实际用到的时候才分配。

Linux是允许memory overcommit的，只要你来申请内存我就给你，寄希望于进程实际上用不到那么多内存，但万一用到那么多了呢？那就会发生类似“银行挤兑”的危机，
现金(内存)不足了。Linux设计了一个OOM killer机制(OOM = out-of-memory)来处理这种危机：挑选一个进程出来杀死，以腾出部分内存，如果还不够就继续杀…
也可通过设置内核参数 vm.panic_on_oom 使得发生OOM时自动重启系统。这都是有风险的机制，重启有可能造成业务中断，杀死进程也有可能导致业务中断，
所以Linux 2.6之后允许通过内核参数 vm.overcommit_memory 禁止memory overcommit。

内核参数 vm.overcommit_memory 接受三种取值：

* 0 – Heuristic overcommit handling. 这是缺省值，它允许overcommit，但过于明目张胆的overcommit会被拒绝，
比如malloc一次性申请的内存大小就超过了系统总内存。Heuristic的意思是“试探式的”，内核利用某种算法（对该算法的详细解释请看文末）
猜测你的内存申请是否合理，它认为不合理就会拒绝overcommit。
* 1 – Always overcommit. 允许overcommit，对内存申请来者不拒。
* 2 – Don’t overcommit. 禁止overcommit。关于禁止overcommit (vm.overcommit_memory=2) ，需要知道的是，怎样才算是overcommit呢？
kernel设有一个阈值，申请的内存总数超过这个阈值就算overcommit，在/proc/meminfo中可以看到这个阈值的大小：

```
# grep -i commit /proc/meminfo
CommitLimit:     5967744 kB
Committed_AS:    5363236 kB
```
CommitLimit 就是overcommit的阈值，申请的内存总数超过CommitLimit的话就算是overcommit。
这个阈值是如何计算出来的呢？它既不是物理内存的大小，也不是free memory的大小，它是通过内核参数vm.overcommit_ratio或vm.overcommit_kbytes间接设置的，公式如下：

```
CommitLimit = (Physical RAM * vm.overcommit_ratio / 100) + Swap
```

注：vm.overcommit_ratio 是内核参数，缺省值是50，表示物理内存的50%。如果你不想使用比率，也可以直接指定内存的字节数大小，通过另一个内核参数 vm.overcommit_kbytes 即可；
如果使用了huge pages，那么需要从物理内存中减去，公式变成：
```
CommitLimit = ([total RAM] – [total huge TLB RAM]) * vm.overcommit_ratio / 100 + swap
```

参见https://access.redhat.com/solutions/665023

/proc/meminfo中的 Committed_AS 表示所有进程已经申请的内存总大小，（注意是已经申请的，不是已经分配的），
如果 Committed_AS 超过 CommitLimit 就表示发生了 overcommit，超出越多表示 overcommit 越严重。
Committed_AS 的含义换一种说法就是，如果要绝对保证不发生OOM (out of memory) 需要多少物理内存。

“sar -r”是查看内存使用状况的常用工具，它的输出结果中有两个与overcommit有关，kbcommit 和 %commit：
kbcommit对应/proc/meminfo中的 Committed_AS；%commit的计算公式并没有采用 CommitLimit作分母，
而是Committed_AS/(MemTotal+SwapTotal)，意思是_内存申请_占_物理内存与交换区之和_的百分比。

```
$ sar -r
05:00:01 PM kbmemfree kbmemused  %memused kbbuffers  kbcached  kbcommit   %commit  kbactive   kbinact   kbdirty
05:10:01 PM    160576   3648460     95.78         0   1846212   4939368     62.74   1390292   1854880         4
```
附：对Heuristic overcommit算法的解释
内核参数 vm.overcommit_memory 的值0，1，2对应的源代码如下，其中heuristic overcommit对应的是OVERCOMMIT_GUESS：

path：include/linux/mman.h
```
#define OVERCOMMIT_GUESS                0
#define OVERCOMMIT_ALWAYS               1
#define OVERCOMMIT_NEVER                2
```

Heuristic overcommit算法在以下函数中实现，基本上可以这么理解：
单次申请的内存大小不能超过 【free memory + free swap + pagecache的大小 + SLAB中可回收的部分】，否则本次申请就会失败。

### security_vm_enough_memory_mm

security_vm_enough_memory_mm进行广泛的安全性和合理性检查，
以防止应用程序设置无效的参数或可能影响系统稳定性的参数.

path: security/security.c
```
int security_vm_enough_memory_mm(struct mm_struct *mm, long pages)
{
	struct security_hook_list *hp;
	int cap_sys_admin = 1;
	int rc;

	/*
	 * The module will respond with a positive value if
	 * it thinks the __vm_enough_memory() call should be
	 * made with the cap_sys_admin set. If all of the modules
	 * agree that it should be set it will. If any module
	 * thinks it should not be set it won't.
	 */
	hlist_for_each_entry(hp, &security_hook_heads.vm_enough_memory, list) {
		rc = hp->hook.vm_enough_memory(mm, pages);
		if (rc <= 0) {
			cap_sys_admin = 0;
			break;
		}
	}
	return __vm_enough_memory(mm, pages, cap_sys_admin);
}
```

### __vm_enough_memory

path: mm/util.c
```
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