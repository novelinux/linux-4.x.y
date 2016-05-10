double_list
========================================

内核每个较大的数据结构中几乎都会出现双链表，
因此内核为实现双链表提供了若干通用函数和结构,
用于各个目的

path: include/linux/types.h
```
struct list_head {
    struct list_head *next, *prev;
};
```

其成员定义很清楚，next指向下一个链表元素，而prev指向前一个链表
元素.链表的组织也是循环的，即第一个链表元素的前一项是链表中的
最后一个元素，而最后一个链表元素的下一项是链表中的第一个元素.

链表的遍历
----------------------------------------

path: include/linux/list.h
```
/**
 * list_for_each_entry    -    iterate over list of given type
 * @pos:    the type * to use as a loop cursor.
 * @head:    the head for your list.
 * @member:    the name of the list_head within the struct.
 */
#define list_for_each_entry(pos, head, member)                \
    for (pos = list_first_entry(head, typeof(*pos), member);    \
         &pos->member != (head);                    \
         pos = list_next_entry(pos, member))
```

path: include/linux/list.h
```
/**
 * list_entry - get the struct for this entry
 * @ptr:    the &struct list_head pointer.
 * @type:    the type of the struct this is embedded in.
 * @member:    the name of the list_head within the struct.
 */
#define list_entry(ptr, type, member) \
    container_of(ptr, type, member)

/**
 * list_first_entry - get the first element from a list
 * @ptr:    the list head to take the element from.
 * @type:    the type of the struct this is embedded in.
 * @member:    the name of the list_head within the struct.
 *
 * Note, that list is expected to be not empty.
 */
#define list_first_entry(ptr, type, member) \
    list_entry((ptr)->next, type, member)
```

container_of
----------------------------------------

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/appendix/container_of/container_of.md