Task Virtual Memory Layout
========================================

用户层进程的虚拟地址空间是Linux的一个重要抽象：
它向每个运行进程提供了同样的系统视图，这使得多个进程可以同时
运行，而不会干扰到其他进程内存中的内容。此外，它容许使用各种
高级的程序设计技术，如内存映射。这同样需要考察可用物理内存中
的页帧与所有的进程虚拟地址空间中的页之间的关联：逆向映射
（reverse mapping）技术有助于从虚拟内存页跟踪到对应的物理内存
页，而缺页处理（page faulthandling）则允许从块设备按需读取数据
填充虚拟地址空间。

如下方法通常是内核用于管理用户虚拟地址空间的方法:

* 每个应用程序都有自身的地址空间，与所有其它应用程序分离.

* 通常在巨大的线性地址空间中，只有很少的段可用于各个用户空间
  进程，这些段彼此之间有一定距离内核需要一些数据结构来有效管理
  这些随机分布的段.

* 地址空间只有极小的一部分与物理内存页直接关联。不经常使用的
  部分，仅当必要时与页帧关联.

* 内核信任自身，但无法信任用户进程。因此各个操作都伴随有各种
  检查，以确保程序的权限不会超出应有的限制，进而危机系统的稳
  定性和安全性.

Address Space
----------------------------------------

各个进程的虚拟地址空间起始于地址0，延伸到TASK_SIZE- 1，其上是
内核地址空间。在ARM系统上地址空间的范围可达232 = 4 GiB，总的
地址空间通常按3:1比例划分。内核分配了1 GiB，而各个用户空间进程
可用的部分为3 GiB。其他的划分比例也是可能的，只能在非常特定的
配置和某些工作负荷下才有用。与系统完整性相关的非常重要的一方面
是，用户程序只能访问整个地址空间的下半部分，不能访问内核部分。
如果没有预先达成“协议”，用户进程也不可能操作另一个进程的地址
空间，因为后者的地址空间对前者不可见。无论当前哪个用户进程处于
活动状态，虚拟地址空间内核部分的内容总是同样的。取决于具体的
硬件，这可能是通过操作各用户进程的页表，使得虚拟地址空间的
上半部看上去总是相同的。也可能是指示处理器为内核提供一个独立的
地址空间，映射在各个用户地址空间之上。虚拟地址空间由许多不同长度
的段组成，用于不同的目的，必须分别处理。例如在大多数情况下，
不允许修改text段，但必须可以执行其内容。另一方面，必须可以修改
映射到地址空间中的文本文件内容，而不能允许执行其内容。因为这
没有意义，文件的内容只是数据，并非机器代码。

Layout
----------------------------------------

虚拟地址空间中包含了若干区域，其分布方式是特定于体系结构的，
但所有方法都有下列共同的成分:

* 当前运行代码的二进制代码.该代码通常称之为text，所处的虚拟
  内存区域称之为text段;
* 程序使用的动态库的代码;
* 存储全局变量和动态产生的数据的堆;
* 用于保存局部变量和实现函数/过程调用的栈;
* 环境变量和命令行参数的段;
* 将文件内容映射到虚拟地址空间中的虚拟内存映射;

下图说明了前述的各个部分在大多数体系结构的虚拟地址空间中的分布
情况:

https://github.com/novelinux/linux-4.x.y/tree/master/mm/mmap.c/res/old_layout.jpg

text段如何映射到虚拟地址空间中由ELF标准确定。每个体系结构
都指定了一个特定的起始地址。堆紧接着text段开始，向上增长。
栈起始于STACK_TOP，如果设置了PF_RANDOMIZE，则起始点会减少一个
小的随机量。每个体系结构都必须定义STACK_TOP，大多数都设置为
TASK_SIZE，即用户地址空间中最高的可用地址。进程的参数列表和
环境变量都是栈的初始数据。用于内存映射的区域起始于
mm_struct->mmap_base，通常设置为TASK_UNMAPPED_BASE，每个体系
结构都需要定义。几乎所有的情况下，其值都是TASK_SIZE/3。
要注意，如果使用内核的默认配置，则mmap区域的起始点不是随机的。

如果计算机提供了巨大的虚拟地址空间，那么使用上述的地址空间布局
会工作得非常好。但在32位计算机上可能会出问题. 对于每个用户进程
其虚拟地址空间从0到0xc0000000,有3GB可用. TASK_UNMAPPED_BASE
起始于0x40000000, 即1GB处.糟糕的是，堆只有1GB空间可用继续增长
会进入到mmap区域. 问题在于内存映射区域位于虚拟地址空间中间.
从2.6.7引入了一个新的虚拟地址空间布局.

https://github.com/novelinux/linux-4.x.y/tree/master/mm/mmap.c/res/new_layout.jpg

其目的在于使用固定值限制栈的最大长度. 由于栈是有界的，因此安置
内存映射的区域可以在栈末端的下方开始.与经典方法相反，改区域现在
是自顶向下扩展。由于堆仍然位于虚拟地址空间中较低的区域并向上
增长，因此mmap区域和堆区域可以相对扩展，直至耗尽虚拟地址空间中
剩余的区域。为确保栈和mmap区域不发生冲突，在两者之间设置一个
安全间隙.

### Pick Layout

在使用load_elf_binary装载一个ELF二进制文件时，setup_new_exec创建进程的地址空间，
选择布局的工作由arch_pick_mmap_layout完成.

#### ARM

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/mm/mmap.c/arch_pick_mmap_layout.md

Principle
----------------------------------------

由于所有用户进程总的虚拟地址空间比可用的物理内存大得多，因此只有最常用的部分才与物理页帧关联。
这不是问题，因为大多数程序只占用实际可用内存的一小部分。我们考察一下通过文本编辑器操作文件的情况。
通常用户只关注文件结尾处，因此尽管整个文件都映射到内存中，实际上只使用了几页来存储文件末尾的数据。
至于文件开始处的数据，内核只需要在地址空间保存相关信息，如数据在磁盘上的位置，以及需要数据时如何读取。

text段的情形类似，始终需要的只是其中一部分。继续考虑文本编辑器的例子，那么就只需要加载与
主要编辑功能相关的代码。其他部分，如帮助系统或所有程序通用的Web和电子邮件客户端程序，只会
在用户明确要求时才加载。内核必须提供数据结构，以建立虚拟地址空间的区域和相关数据所在位置之间
的关联。例如，在映射文本文件时，映射的虚似内存区必须关联到文件系统在硬盘上存储文件内容的区域。
如图所示:

https://github.com/novelinux/linux-4.x.y/tree/master/mm/mmap.c/res/vma-file-map.jpg

给出的图示是简化的，因为文件数据在硬盘上的存储通常并不是连续的，而是分布到若干小的区域。内核利用
address_space数据结构，提供一组方法从后备存储器读取数据。例如，从文件系统读取。因此address_space
形成了一个辅助层，将映射的数据表示为连续的线性区域，提供给内存管理子系统。按需分配和填充页称之为
按需调页法（demand paging）。它基于处理器和内核之间的交互，使用的各种数据结构如图所示:

https://github.com/novelinux/linux-4.x.y/tree/master/mm/mmap.c/res/map-data-structure.jpg

* 进程试图访问用户地址空间中的一个内存地址，但使用页表无法确定物理地址（物理内存中没有关联页）。
* 处理器接下来触发一个缺页异常，发送到内核。
* 内核会检查负责缺页区域的进程地址空间数据结构，找到适当的后备存储器，或者确认该访问实际上是不正确的。
* 分配物理内存页，并从后备存储器读取所需数据填充。
* 借助于页表将物理内存页并入到用户进程的地址空间，应用程序恢复执行。

这些操作对用户进程是透明的。换句话说，进程不会注意到页是实际在物理内存中，还是需要通过按需调页加载。

Data Structure
----------------------------------------

### struct task_struct

```
    struct mm_struct *mm, *active_mm;
```

系统中的各个进程都具有一个struct mm_struct的实例，可以通过
task_struct访问。这个实例保存了进程的内存管理信息:

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/mm_types.h/res/task_mm.jpg

### struct mm_struct

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/mm_types.h/struct_mm_struct.md

### struct vm_area_struct

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/mm_types.h/struct_vm_area_struct.md

### struct vm_unmapped_area_info

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/mm.h/struct_vm_unmapped_area_info.md

### struct address_space

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/fs.h/struct_address_space.md

尽管只讨论文件区间的映射，但实际上也可以映射不同的东西。例如，直接映射裸（raw）块设备上的区间，
而不通过文件系统迂回。在打开文件时，内核将file->f_mapping设置到inode->i_mapping。这使得多个进程
可以访问同一个文件，而不会直接干扰到其他进程：inode是一个特定于文件的数据结构，而file则是特定于
给定进程的。这些数据结构彼此关联:

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/fs.h/res/file-inode-address_space.jpg

地址空间是优先树的基本要素，而优先树包含了所有相关的vm_area_struct实例，描述了与inode关联的
文件区间到一些虚拟地址空间的映射。由于每个struct vm_area的实例都包含了一个指向所属进程的
mm_struct的指针，关联就已经建立起来了.

Initialization
----------------------------------------

### bprm_mm_init

创建一个mm_struct实例管理新进程的进程地址空间.

https://github.com/novelinux/linux-4.x.y/blob/master/fs/exec.c/bprm_mm_init.md

### __bprm_mm_init

https://github.com/novelinux/linux-4.x.y/blob/master/fs/exec.c/__bprm_mm_init.md

### exec_mmap

https://github.com/novelinux/linux-4.x.y/blob/master/fs/exec.c/exec_mmap.md

### setup_new_exec

https://github.com/novelinux/linux-4.x.y/blob/master/fs/exec.c/setup_new_exec.md

### setup_arg_pages

https://github.com/novelinux/linux-4.x.y/tree/master/fs/exec.c/setup_arg_pages.md

APIS
----------------------------------------

### VMA

#### find_vma

将虚拟地址关联到区域:

https://github.com/novelinux/linux-4.x.y/tree/master/mm/mmap.c/find_vma.md

#### vma_merge

区域合并:

https://github.com/novelinux/linux-4.x.y/tree/master/mm/mmap.c/vma_merge.md

#### insert_vm_struct

插入区域:

https://github.com/novelinux/linux-4.x.y/tree/master/mm/mmap.c/insert_vm_struct.md

#### get_unmapped_area

https://github.com/novelinux/linux-4.x.y/tree/master/mm/mmap.c/get_unmapped_area.md

### mmap

```
mmap +-> mmap64 +-> __mmap2 ---+
                               |
sys_mmap_pgoff <-+ sys_mmap2 <-+
 |
 +-> vm_mmap_pgoff
     |
     +-> do_mmap_pgoff
         |
         +-> do_mmap
             |
             +-> get_unmapped_area
             |   |
             |   +-> arch_get_unmapped_area_topdown
             |
             +-> mmap_region
                 |
                 +-> may_expand_vm
                 |
                 +-> find_vma_links
                 |
                 +-> accountable_mapping
                 |
                 +-> vma_merge
```

https://github.com/novelinux/system_calls/blob/master/mmap/mmap.md

#### sys_mmap2

https://github.com/novelinux/linux-4.x.y/tree/master/mm/mmap.c/sys_mmap2.md

### sys_brk

https://github.com/novelinux/linux-4.x.y/tree/master/mm/mmap.c/sys_brk.md

Page Fault
----------------------------------------

在实际需要某个虚拟内存区域的数据之前，虚拟和物理内存之间的关联不会建立。
如果进程访问的虚拟地址空间部分尚未与页帧关联，处理器自动地引发一个缺页异常，
内核必须处理此异常。这是内存管理中最重要、最复杂的方面之一，因为必须考虑到无数的细节。
例如，内核必须确定以下情况。
* 缺页异常是由于访问用户地址空间中的有效地址而引起，还是应用程序试图访问内核的受保护区域?
* 目标地址对应于某个现存的映射吗？
* 获取该区域的数据，需要使用何种机制？

内核在处理缺页异常时，可能使用的各种代码路径的一个粗略的概观。

https://github.com/novelinux/linux-4.x.y/tree/master/mm/mmap.c/res/page_fault_framework.jpg

按下文的讲述，实际上各个操作都要复杂得多，因为内核不仅要防止来自用户空间的恶意访问，
还要注意许多细枝末节。此外，决不能因为缺页处理的相关操作而不必要地降低系统性能。
缺页处理的实现因处理器的不同而有所不同。由于CPU采用了不同的内存管理概念，生成缺页
异常的细节也不太相同。因此，缺页异常的处理例程在内核代码中位于特定于体系结构的部分。

### ARM

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/mm/fault.c/README.md

## MEMORY OVERCOMMIT

https://github.com/novelinux/linux-4.x.y/tree/master/mm/mmap.c/memory_overcommit.md