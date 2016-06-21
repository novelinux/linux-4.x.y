struct iov_iter
========================================

path: include/linux/uio.h
```
struct iov_iter {
    int type;
    size_t iov_offset;
    size_t count;
    union {
        const struct iovec *iov;
        const struct kvec *kvec;
        const struct bio_vec *bvec;
    };
    unsigned long nr_segs;
};
```