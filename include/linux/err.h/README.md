LINUX ERR
========================================

Linux有时候在操作成功时需要返回指针，而在失败时则返回错误码。
遗憾的是，C语言每个函数只允许一个直接的返回值，因此任何有关可能
错误的信息都必须编码到指针中。虽然一般而言指针可以指向内存中的
任意位置，而Linux支持的每个体系结构的虚拟地址空间中都有一个从
虚拟地址0到至少4 KiB的区域，该区域中没有任何有意义的信息。因此
内核可以重用该地址范围来编码错误码。如果fork的返回值指向前述的
地址范围内部，那么该调用就失败了，其原因可以由指针的数值判断。
ERR_PTR是一个辅助宏，用于将数值常数(例如EINVAL，非法操作)编码
为指针:

ERR_PTR and PTR_ERR
----------------------------------------

path: include/linux/err.h
```
/*
 * Kernel pointers have redundant information, so we can use a
 * scheme where we can return either an error code or a dentry
 * pointer with the same return value.
 *
 * This should be a per-architecture thing, to allow different
 * error and pointer decisions.
 */
#define MAX_ERRNO    4095

#ifndef __ASSEMBLY__

#define IS_ERR_VALUE(x) unlikely((x) >= (unsigned long)-MAX_ERRNO)

static inline void * __must_check ERR_PTR(long error)
{
    return (void *) error;
}

static inline long __must_check PTR_ERR(const void *ptr)
{
    return (long) ptr;
}

static inline long __must_check IS_ERR(const void *ptr)
{
    return IS_ERR_VALUE((unsigned long)ptr);
}
```

内核空间是一个有限的空间,而在这有限的空间中,其最后一个page是专门保留的,也就是说一般人不可能用到
内核空间最后一个page的.换句话说,你在写设备驱动程序的过程中,涉及到的任何一个指针,必然有三种情况,
一种是有效指针,一种是NULL,空指针,一种是错误指针,或者说无效指针.而所谓的错误指针就是指其已经到达
了最后一个page.比如对于32bit的系统来说,内核空间最高地址0xffffffff,那么最后一个page就是指的
0xfffff000~0xffffffff(假设4k一个page).这段地址是被保留的,一般人不得越雷池半步,如果发现一个指针指
向这个范围中的某个地址,那么恭喜你,你的代码肯定出错了.

那么你是不是很好奇,好端端的内核空间干嘛要留出最后一个page?这不是缺心眼儿吗?明明自己有1000块钱,
非得对自己说只能用900块.实在不好意思,你说错了,这里不仅不是浪费一个page,反而是充分利用资源,把一个
东西当两个东西来用.

我们知道内存相关的函数如kmalloc的返回值一般是一个4k对齐的虚拟地址，也有可能是NULL.
以32位系统为例，我们知道存储地址值变量类型是unsigned无符号的。那么这个物尽其用，体现在哪里呢？
地址都是4k对齐那么0XFFFFF000 ~0XFFFFFFFF这4k个地址就没人用了。
当然所有不被4k整除的地址都用不到，而内核就选择了这最后一个page的地址了。
内核用的就是这个范围内的数字。在error_base.h你会看到定义的各种错误量。
把这些错误量前面加个-负号，他们的补码形式正好落在这4k范围内。这就用上了，和原来表示地址也不会冲突。
有了这些值我们就知道具体是什么错误了，比简单返回一个NULL强百倍。

ERR_PTR,PTR_ERR都很简单。解释下IS_ERR:

MAX_ERRNO值是4095对应的负数值-4095，也就是0XFFFFF001.
EPERM值是1对应负数的补码值就是：0XFFFFFFF1.
以此类推，所有err值都大于-4095。就能区分错误码和4k对齐的虚拟地址了，因为内存管理函数返回的虚拟地址
的值永不会大于-4095.
