# user_path_parent

函数user_path_parent主要执行path walking，我们下面来看看这个函数的内核实现。函数原型如下：

```
/*
 * NB: most callers don't do anything directly with the reference to the
 *     to struct filename, but the nd->last pointer points into the name string
 *     allocated by getname. So we must hold the reference to it until all
 *     path-walking is complete.
 */
static inline struct filename *
user_path_parent(int dfd, const char __user *path,
                 struct path *parent,
                 struct qstr *last,
                 int *type,
                 unsigned int flags)
{
	/* only LOOKUP_REVAL is allowed in extra flags */
	return filename_parentat(dfd, getname(path), flags & LOOKUP_REVAL,
                                 parent, last, type);
}
```

## struct filename

函数返回值是filename结构体，参数分别是系统调用传入的dfd参数，存储在用户空间的path，最后是一个标志位。

https://github.com/novelinux/linux-4.x.y/blob/master/include/linux/fs.h/struct_filename.md

## getname

https://github.com/novelinux/linux-4.x.y/blob/master/fs/namei.c/getname.md

## filename_parentat

https://github.com/novelinux/linux-4.x.y/blob/master/fs/namei.c/filename_parentat.md

对于文件系统的大部分操作（open、stat、unlink等等）都要涉及多多少少的路径解析。
路劲解析是根据路径名（name string）得到对应的dentry对象，通过路径行走的方式。

## 路径行走解释

路径是由一个开始字符（根目录、当前工作目录或者fd指向的目录），和一串其他的文件名组成的，
path中的每一个文件名用/分割开。名称查找（Name Lookup）就是希望根据已知的path和name的
开始指针找到path中的最后一个文件名或者最后一个文件的父文件名。根据name指针找path中要
求的当前父亲文件的孩子文件，如果孩子并不是最后一个path组件（component），孩子文件称为
新的父文件，迭代这个过程，就像是在path上行走一样，因此被称为路径行走。
这个过程要求父亲必须是一个目录，并且我们对父亲文件的inode节点拥有读权限。为了下一步查找
把孩子文件变成父亲文件的时候，要求更多的检测规程。符号链接实质上是链接所指向文件的替代，
符号链接要求递归的路径行走。挂载点必须被跟踪(因此改变vfsmount的后续路径元素引用),
从挂载点路径切换到特定的安装vfs mount的根目录。这些不同的修改行为取决于具体的路径行走标志。

## 路径行走必须做下面几件事：

* 找到行走的起点
* 执行权限和有效性检查
* 执行目录项缓存元组上的的哈希name查找
* 遍历挂载点
* 遍历符号链接
* 查找或者创建要求路径中的文件

路径行走有两个模式：rcu_walk模式和ref_walk模式。

ref-walk是传统的使用自旋锁（d_lock）去并发修改目录项。比起rcu-walk这个模式，ref-walk是操作简单，
但是在在路劲行走的过程中，对于每一个目录项的操作可能需要睡眠、得到锁等等这些操作。rcu-walk
是基于顺序锁的目录项查找，可以不用存储任何共享数据在目录项或inode里，查找中间的元素。
rcu-walk并不适合与任何一种情况，比如说：如果文件系统必须沉睡或者执行不重要的操作，
就需要切换到ref-walk模式。

在 rcu-walk 期间将会禁止抢占，也决不能出现进程阻塞，所以其效率很高；ref-walk 会在 rcu-walk 失败、
进程需要随眠或者需要取得某结构的引用计数（reference count）的情况下切换进来，很明显它的效率大大低于

## 路径行走的过程总结

路径行走到底是在找什么呢？说的简单一点，就是在找路径所指向的文件的父目录项。因为整个查找过程是一个
分量一个分量的查找的，就像是在路径上行走一样，因此成为路径行走。行走结束，得到对应的dentry。

### 1.中间数据

* nd变量：用来保存找到的当前分量dentry我们需要的信息，而且这个分量一定是一个普通的、真正的目录。
* path变量：既然nd变量只能保存真正目录的信息，如果我们得到了一个分量，我们在确定这个分量是真正的目录之前，找到的dentry信息就用path变量保存。
* name变量：指向路径中当前的分量开始位置

### 2.大致过程

在内核空间申请一页空间，把存储在用户空间的路径信息拷贝到内核空间，初次创建nd结构体。
初始化nd结构体，理想情况下，nd保存的是name指针指向的分量的上一个分量信息，原因还是因为nd结构体要求
保存真正的目录的信息。如果路径是绝对路径，nd结构体初始化为根目录的dentry信息，如果路径是相对路径，
nd结构体初始化位当前进程cwd的dentry信息。
开始”行走“第一个分量，这个分量信息在初始化的时候填充完成，因此第一次行走要做的工作并不多。然后移动
name指针指向第二个分量，如果这个分量是普通目录，行走这个分量：

根据分量名的hash值在内核缓冲区查找dentry
如果没有找到，调用文件系统自身的lookup，
并循环执行上面过程。
如果这个分量是.目录或者..目录，则：

如果是.目录，直接返回0。对于当前目录并不需要做任何操作
如果是..目录，找到父目录的dentry，填充nd结构体
如果这个分量是符号链接：
找到符号链接指向的文件的dentry，填充nd结构体