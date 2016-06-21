iov_iter_copy_from_user_atomic
========================================

path: lib/iov_iter.c
```
size_t iov_iter_copy_from_user_atomic(struct page *page,
        struct iov_iter *i, unsigned long offset, size_t bytes)
{
    char *kaddr = kmap_atomic(page), *p = kaddr + offset;
    iterate_all_kinds(i, bytes, v,
        __copy_from_user_inatomic((p += v.iov_len) - v.iov_len,
                      v.iov_base, v.iov_len),
        memcpy_from_page((p += v.bv_len) - v.bv_len, v.bv_page,
                 v.bv_offset, v.bv_len),
        memcpy((p += v.iov_len) - v.iov_len, v.iov_base, v.iov_len)
    )
    kunmap_atomic(kaddr);
    return bytes;
}
EXPORT_SYMBOL(iov_iter_copy_from_user_atomic);
```
