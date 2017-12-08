# getname_flags

path: fs/namei.c
```
/* In order to reduce some races, while at the same time doing additional
 * checking and hopefully speeding things up, we copy filenames to the
 * kernel data space before using them..
 *
 * POSIX.1 2.4: an empty pathname is invalid (ENOENT).
 * PATH_MAX includes the nul terminator --RR.
 */

#define EMBEDDED_NAME_MAX    (PATH_MAX - offsetof(struct filename, iname))

struct filename *
getname_flags(const char __user *filename, int flags, int *empty)
{
    struct filename *result;
    char *kname;
    int len;

    result = audit_reusename(filename);
    if (result)
        return result;
```

## __getname


```
#define __getname()             kmem_cache_alloc(names_cachep, GFP_KERNEL)
```

__getname函数，为了避免本文边的很冗长，这个函数我们暂且不具体分析。他的功能就是在内核空间分配
4096字节的空间，然后把地址赋给result，kname保存分配到的这篇空间的尾地址，并且把这个地址赋给
filename的name成员变量，这里我们可以猜测一下，不管将来name里面保存了什么变量，肯定是存储在
这片空间的末尾的，并且设置这个name不能被释放。EMBEDDED_NAME_MAX这个宏变量的是这页空间存储完
filename结构体以后，还剩多少字节空间，把这个值赋给max变量。开始把存储在用户空间的path拷贝到
内核空间，并且返回拷贝字节数，并且判断拷贝动作是否成功，若出错进行出错处理。

```
    result = __getname();
    if (unlikely(!result))
        return ERR_PTR(-ENOMEM);

    /*
     * First, try to embed the struct filename inside the names_cache
     * allocation
     */
    kname = (char *)result->iname;
    result->name = kname;

    len = strncpy_from_user(kname, filename, EMBEDDED_NAME_MAX);
    if (unlikely(len < 0)) {
        __putname(result);
        return ERR_PTR(len);
    }

    /*
     * Uh-oh. We have a name that's approaching PATH_MAX. Allocate a
     * separate struct filename so we can dedicate the entire
     * names_cache allocation for the pathname, and re-do the copy from
     * userland.
     */
    if (unlikely(len == EMBEDDED_NAME_MAX)) {
        const size_t size = offsetof(struct filename, iname[1]);
        kname = (char *)result;

        /*
         * size is chosen that way we to guarantee that
         * result->iname[0] is within the same object and that
         * kname can't be equal to result->iname, no matter what.
         */
        result = kzalloc(size, GFP_KERNEL);
        if (unlikely(!result)) {
            __putname(kname);
            return ERR_PTR(-ENOMEM);
        }
        result->name = kname;
        len = strncpy_from_user(kname, filename, PATH_MAX);
        if (unlikely(len < 0)) {
            __putname(kname);
            kfree(result);
            return ERR_PTR(len);
        }
        if (unlikely(len == PATH_MAX)) {
            __putname(kname);
            kfree(result);
            return ERR_PTR(-ENAMETOOLONG);
        }
    }

    result->refcnt = 1;
    /* The empty path is special. */
    if (unlikely(!len)) {
        if (empty)
            *empty = 1;
        if (!(flags & LOOKUP_EMPTY)) {
            putname(result);
            return ERR_PTR(-ENOENT);
        }
    }

    result->uptr = filename;
    result->aname = NULL;
    audit_getname(result);
    return result;
}
```

判断如果拷贝到内核空间的path把新分配的这页占满了，kname指向这个空间开始的位置（kname时刻指向
path开始的位置）,然后调用kalloc函数分配再分配一页空间。成功以后，把kname的地址（也就是path
存储在内核空间的首地址赋给result的name域，设置name可以被释放。）并且把之前春初在user空间的
地址存储在result的utpr域 （现在明白了这个原来的用户是什么意思了吧）。获取到aname域，并且填充。
最后返回result。这个getname_flags函数我们就分析完成了。