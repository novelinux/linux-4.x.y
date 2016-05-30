vmlist
========================================

在创建一个新的虚拟内存区之前，必须找到一个适当的位置。vm_area实例组成的一个链表，管理着vmalloc
区域中已经建立的各个子区域。变量vmlist是表头。

path: mm/vmalloc.c
```
static struct vm_struct *vmlist __initdata;
```

vm_area_add_early
----------------------------------------

vmlist的初始化是通过调用函数vm_area_add_early来完成的:
