container_of
========================================

container_of
----------------------------------------

path: include/linux/kernel.h
```
/**
 * container_of - cast a member of a structure out to the containing structure
 * @ptr:    the pointer to the member.
 * @type:    the type of the container struct this is embedded in.
 * @member:    the name of the member within the struct.
 *
 */
#define container_of(ptr, type, member) ({                  \
    const typeof( ((type *)0)->member ) *__mptr = (ptr);    \
    (type *)( (char *)__mptr - offsetof(type,member) );})

```

container_of从结构体的成员变量获得包含成员的结构体实例.
* ptr - 指向成员数据的指针.
* type - 所嵌入到容器结构的类型.
* member - 成员在结构内的名称.

offsetof
----------------------------------------

path: include/linux/stddef.h
```
#undef offsetof
#ifdef __compiler_offsetof
#define offsetof(TYPE,MEMBER) __compiler_offsetof(TYPE,MEMBER)
#else
#define offsetof(TYPE, MEMBER) ((size_t) &((TYPE *)0)->MEMBER)
#endif
#endif
```

下面我们通过一个实例来描述这两个宏的使用

Example
----------------------------------------

```
#include <stdio.h>

#define offsetof(TYPE, MEMBER) ((size_t) &((TYPE *)0)->MEMBER)
#define container_of(ptr, type, member) ({                          \
            const typeof( ((type *)0)->member ) *__mptr = (ptr);    \
            (type *)( (char *)__mptr - offsetof(type,member) );})

struct A {
    int b;
    int c;
    int d;
    int e;
};

int main(int argc, char *argv[])
{
    struct A a;

    a.b = 1;
    a.c = 2;
    a.d = 3;
    a.e = 4;

    long off_d = offsetof(struct A, d);
    struct A *ptr = container_of(&a.d, struct A, d);
    printf("off_d=%ld\n", off_d);
    printf("e=%d\n", ptr->e);

    return 0;
}
```

Results:

```
off_d=8
e=4
```

在本例中offsetof宏展开如下所示：

```
(size_t) &((struct A *)0)->d
```

通过类型转换，将空指针0转换为一个指向struct A的指针。这是允许的，
因为我们并不反引用该指针。接下来执行->和&(->的优先级大于&)获得的地址
计算出了d成员相对于struct A实例的偏移量。在例子中，该成员位于该
结构的8字节位置处，因而返回值是8.

有了这一信息之后，container_of宏就能够着手提取容器数据结构的实例。
在例子中代码展开如下所示:

```
const int *__mptr = (ptr);
(struct A*)((char *)__mptr - off_d);
```

ptr指向指向结构体中的&a.d. 内核首先创建一个指针__mptr,其值与ptr相同，
指向所要求的目标数据类型是int. 接下来，使用此前计算的偏移量值来
移动__mptr, 使之不再指向d元素，而是指向结构体首地址。为确保指针
运算是按照字节执行的，先将__mptr转换为char *指针。但在计算完成
后的赋值操作中，又转换回原来的数据类型。