generic_perform_write
========================================

generic_perform_write函数是把数据写入磁盘的主要处理函数。它先调用address_space_operations的
write_begin,其中会调用__block_write_begin函数，接下来把数据拷贝到上一步分配出来的page中，
最后调用address_space_operations.write_end。上面所说的write_begin和write_end会具体根据不同的
file system调用不同的函数.

Arguments
----------------------------------------

path: mm/filemap.c
```
ssize_t generic_perform_write(struct file *file,
                struct iov_iter *i, loff_t pos)
{
    struct address_space *mapping = file->f_mapping;
    const struct address_space_operations *a_ops = mapping->a_ops;
    long status = 0;
    ssize_t written = 0;
    unsigned int flags = 0;

    /*
     * Copies from kernel address space cannot fail (NFSD is a big user).
     */
    if (!iter_is_iovec(i))
        flags |= AOP_FLAG_UNINTERRUPTIBLE;
```

Do Write
----------------------------------------

```
    do {
        struct page *page;
        unsigned long offset; /* Offset into pagecache page */
        unsigned long bytes;  /* Bytes to write to page */
        size_t copied;        /* Bytes copied from user */
        void *fsdata;

        offset = (pos & (PAGE_CACHE_SIZE - 1));
        bytes = min_t(unsigned long, PAGE_CACHE_SIZE - offset,
                        iov_iter_count(i));

again:
        /*
         * Bring in the user page that we will copy from _first_.
         * Otherwise there's a nasty deadlock on copying from the
         * same page as we're writing to, without it being marked
         * up-to-date.
         *
         * Not only is this an optimisation, but it is also required
         * to check that the address is actually valid, when atomic
         * usercopies are used, below.
         */
        if (unlikely(iov_iter_fault_in_readable(i, bytes))) {
            status = -EFAULT;
            break;
        }

        if (fatal_signal_pending(current)) {
            status = -EINTR;
            break;
        }
```

### a_ops->write_begin

```
        status = a_ops->write_begin(file, mapping, pos, bytes, flags,
                        &page, &fsdata);
        if (unlikely(status < 0))
            break;

        if (mapping_writably_mapped(mapping))
            flush_dcache_page(page);
```

#### EXT4

* super block指定DELALLOC标志.

https://github.com/novelinux/linux-4.x.y/blob/master/fs/ext4/inode.c/ext4_da_aops.md

### iov_iter_copy_from_user_atomic

```
        copied = iov_iter_copy_from_user_atomic(page, i, offset, bytes);
        flush_dcache_page(page);
```

https://github.com/novelinux/linux-4.x.y/blob/master/lib/iov_iter.c/iov_iter_copy_from_user_atomic.md

### a_ops->write_end

```
        status = a_ops->write_end(file, mapping, pos, bytes, copied,
                        page, fsdata);
        if (unlikely(status < 0))
            break;
        copied = status;

        cond_resched();
```

#### EXT4

* super block指定DELALLOC标志.

https://github.com/novelinux/linux-4.x.y/blob/master/fs/ext4/inode.c/ext4_da_aops.md

### iov_iter_advance

```
        iov_iter_advance(i, copied);
        if (unlikely(copied == 0)) {
            /*
             * If we were unable to copy any data at all, we must
             * fall back to a single segment length write.
             *
             * If we didn't fallback here, we could livelock
             * because not all segments in the iov can be copied at
             * once without a pagefault.
             */
            bytes = min_t(unsigned long, PAGE_CACHE_SIZE - offset,
                        iov_iter_single_seg_count(i));
            goto again;
        }
        pos += copied;
        written += copied;

        balance_dirty_pages_ratelimited(mapping);
```

https://github.com/novelinux/linux-4.x.y/blob/master/lib/iov_iter.c/iov_iter_advance.md

### iov_iter_count

```
    } while (iov_iter_count(i));

    return written ? written : status;
}
EXPORT_SYMBOL(generic_perform_write);
```

https://github.com/novelinux/linux-4.x.y/blob/master/include/linux/uio.h/iov_iter_count.md
