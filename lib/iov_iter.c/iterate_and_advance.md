iterate_and_advance
========================================

path: fs/iov_iter.c
```
#define iterate_and_advance(i, n, v, I, B, K) {            \
    size_t skip = i->iov_offset;                \
    if (unlikely(i->type & ITER_BVEC)) {            \
        const struct bio_vec *bvec;            \
        struct bio_vec v;                \
        iterate_bvec(i, n, v, bvec, skip, (B))        \
        if (skip == bvec->bv_len) {            \
            bvec++;                    \
            skip = 0;                \
        }                        \
        i->nr_segs -= bvec - i->bvec;            \
        i->bvec = bvec;                    \
    } else if (unlikely(i->type & ITER_KVEC)) {        \
        const struct kvec *kvec;            \
        struct kvec v;                    \
        iterate_kvec(i, n, v, kvec, skip, (K))        \
        if (skip == kvec->iov_len) {            \
            kvec++;                    \
            skip = 0;                \
        }                        \
        i->nr_segs -= kvec - i->kvec;            \
        i->kvec = kvec;                    \
    } else {                        \
        const struct iovec *iov;            \
        struct iovec v;                    \
        iterate_iovec(i, n, v, iov, skip, (I))        \
        if (skip == iov->iov_len) {            \
            iov++;                    \
            skip = 0;                \
        }                        \
        i->nr_segs -= iov - i->iov;            \
        i->iov = iov;                    \
    }                            \
    i->count -= n;                        \
    i->iov_offset = skip;                    \
}
```
