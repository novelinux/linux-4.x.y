iov_iter_init
========================================

path: lib/iov_iter.c
```
void iov_iter_init(struct iov_iter *i, int direction,
            const struct iovec *iov, unsigned long nr_segs,
            size_t count)
{
    /* It will get better.  Eventually... */
    if (segment_eq(get_fs(), KERNEL_DS)) {
        direction |= ITER_KVEC;
        i->type = direction;
        i->kvec = (struct kvec *)iov;
    } else {
        i->type = direction;
        i->iov = iov;
    }
    i->nr_segs = nr_segs;
    i->iov_offset = 0;
    i->count = count;
}
EXPORT_SYMBOL(iov_iter_init);
```