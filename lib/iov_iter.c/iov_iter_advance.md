iov_iter_advance
========================================

path: lib/iov_iter.c
```
void iov_iter_advance(struct iov_iter *i, size_t size)
{
    iterate_and_advance(i, size, v, 0, 0, 0)
}
EXPORT_SYMBOL(iov_iter_advance);
```

iterate_and_advance
----------------------------------------

https://github.com/novelinux/linux-4.x.y/blob/master/lib/iov_iter.c/iterate_and_advance.md
