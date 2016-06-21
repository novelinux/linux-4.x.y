__generic_file_write_iter
========================================

Comments
----------------------------------------

path: mm/filemap.c
```
/**
 * __generic_file_write_iter - write data to a file
 * @iocb:    IO state structure (file, offset, etc.)
 * @from:    iov_iter with data to write
 *
 * This function does all the work needed for actually writing data to a
 * file. It does all basic checks, removes SUID from the file, updates
 * modification times and calls proper subroutines depending on whether we
 * do direct IO or a standard buffered write.
 *
 * It expects i_mutex to be grabbed unless we work on a block device or similar
 * object which does not need locking at all.
 *
 * This function does *not* take care of syncing data in case of O_SYNC write.
 * A caller has to handle it. This is mainly due to the fact that we want to
 * avoid syncing under i_mutex.
 */
```

Arguments
----------------------------------------

```
ssize_t __generic_file_write_iter(struct kiocb *iocb, struct iov_iter *from)
{
    struct file *file = iocb->ki_filp;
    struct address_space * mapping = file->f_mapping;
    struct inode     *inode = mapping->host;
    ssize_t        written = 0;
    ssize_t        err;
    ssize_t        status;

    /* We can write back this queue in page reclaim */
    current->backing_dev_info = inode_to_bdi(inode);
    err = file_remove_privs(file);
    if (err)
        goto out;

    err = file_update_time(file);
    if (err)
        goto out;
```

Directory
----------------------------------------

```
    if (iocb->ki_flags & IOCB_DIRECT) {
        loff_t pos, endbyte;

        written = generic_file_direct_write(iocb, from, iocb->ki_pos);
        /*
         * If the write stopped short of completing, fall back to
         * buffered writes.  Some filesystems do this for writes to
         * holes, for example.  For DAX files, a buffered write will
         * not succeed (even if it did, DAX does not handle dirty
         * page-cache pages correctly).
         */
        if (written < 0 || !iov_iter_count(from) || IS_DAX(inode))
            goto out;

        status = generic_perform_write(file, from, pos = iocb->ki_pos);
        /*
         * If generic_perform_write() returned a synchronous error
         * then we want to return the number of bytes which were
         * direct-written, or the error code if that was zero.  Note
         * that this differs from normal direct-io semantics, which
         * will return -EFOO even if some bytes were written.
         */
        if (unlikely(status < 0)) {
            err = status;
            goto out;
        }
        /*
         * We need to ensure that the page cache pages are written to
         * disk and invalidated to preserve the expected O_DIRECT
         * semantics.
         */
        endbyte = pos + status - 1;
        err = filemap_write_and_wait_range(mapping, pos, endbyte);
        if (err == 0) {
            iocb->ki_pos = endbyte + 1;
            written += status;
            invalidate_mapping_pages(mapping,
                         pos >> PAGE_CACHE_SHIFT,
                         endbyte >> PAGE_CACHE_SHIFT);
        } else {
            /*
             * We don't know how much we wrote, so just return
             * the number of bytes which were direct-written
             */
        }
```

generic_perform_write
----------------------------------------

```
    } else {
        written = generic_perform_write(file, from, iocb->ki_pos);
        if (likely(written > 0))
            iocb->ki_pos += written;
    }
out:
    current->backing_dev_info = NULL;
    return written ? written : err;
}
EXPORT_SYMBOL(__generic_file_write_iter);
```

https://github.com/novelinux/linux-4.x.y/blob/master/mm/filemap.c/generic_perform_write.md
