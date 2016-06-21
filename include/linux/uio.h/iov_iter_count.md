iov_iter_count
========================================

path: include/linux/uio.h
```
static inline size_t iov_iter_count(struct iov_iter *i)
{
    return i->count;
}
```