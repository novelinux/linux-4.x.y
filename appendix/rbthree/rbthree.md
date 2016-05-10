rbthree
========================================

属性
----------------------------------------

红黑树是一种自平衡二插搜索树. 其具有如下特征：

* 每个节点或红或黑.
* 每个叶子节点都是黑色的.
* 如果节点为红色，那么两个子节点都是黑色。因而，在从树的根节点
  到任意叶节点的任何路径上，都不会有两个连续红色节点，但可能有
  任意数目的连续黑色节点.
* 从一个内部节点到叶节点的简单路径上，对所有叶节点来说，黑色节点
  的数目都是相同的.

红黑树的优点是：所有重要的树操作(插入，删除，搜索)都可以在O(log n)
时间内完成，n是树中元素的数目.

为了表示RB树的节点，其数据结构不仅需要指向子节点的指针和保存有用
数据的字段，还需要一个成员来保存颜色信息。内核通过以下定义来实现
RB树的节点:

RB树的节点
----------------------------------------

path: include/linux/rbtree.h
```
struct rb_node {
    unsigned long  __rb_parent_color;
    struct rb_node *rb_right;
    struct rb_node *rb_left;
} __attribute__((aligned(sizeof(long))));
/* The alignment might seem pointless, but allegedly CRIS needs it */
```

尽管在结构定义中不能直接看到，但内核维护了一个指向父节点的附加指针.
它隐藏在__rb_parent_color中：只有一个比特位用于表示两种颜色，该信息
保存__rb_parent_color最低的比特位中。该变量其余的比特位用于保存父
节点指针。这是最可能的，因为在所有体系结构上，指针都要求对齐到4字节
边界，因而最低的两个比特位保证为0.但在反引用该指针之前，内核必须将
颜色信息从指针中屏蔽出去，如下所示:

path: include/linux/rbtree.h
```
#define rb_parent(r)   ((struct rb_node *)((r)->__rb_parent_color & ~3))
```

指向红黑树根节点的指针
----------------------------------------

path: include/linux/rbtree.h
```
struct rb_root {
    struct rb_node *rb_node;
};
```

获取包含rb_node结构体首地址
----------------------------------------

```
#define rb_entry(ptr, type, member) container_of(ptr, type, member)
```

为确保RB树的实现是通用的，内核只提供了操作树的通用标准函数，这些
实现在lib/rbthree.c中

container_of
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/appendix/container_of/container_of.md
