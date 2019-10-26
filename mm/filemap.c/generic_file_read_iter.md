## generic_file_read_iter

```
/**
 * generic_file_read_iter - generic filesystem read routine
 * @iocb:	kernel I/O control block
 * @iter:	destination for the data read
 *
 * This is the "read_iter()" routine for all filesystems
 * that can use the page cache directly.
 */
ssize_t
generic_file_read_iter(struct kiocb *iocb, struct iov_iter *iter)
{
	struct file *file = iocb->ki_filp;
	ssize_t retval = 0;
	loff_t *ppos = &iocb->ki_pos;
	loff_t pos = *ppos;

	if (iocb->ki_flags & IOCB_DIRECT) {
		struct address_space *mapping = file->f_mapping;
		struct inode *inode = mapping->host;
		size_t count = iov_iter_count(iter);
		loff_t size;

		if (!count)
			goto out; /* skip atime */
		size = i_size_read(inode);
		retval = filemap_write_and_wait_range(mapping, pos,
					pos + count - 1);
		if (!retval) {
			struct iov_iter data = *iter;
			retval = mapping->a_ops->direct_IO(iocb, &data, pos);
		}

		if (retval > 0) {
			*ppos = pos + retval;
			iov_iter_advance(iter, retval);
		}

		/*
		 * Btrfs can have a short DIO read if we encounter
		 * compressed extents, so if there was an error, or if
		 * we've already read everything we wanted to, or if
		 * there was a short read because we hit EOF, go ahead
		 * and return.  Otherwise fallthrough to buffered io for
		 * the rest of the read.  Buffered reads will not work for
		 * DAX files, so don't bother trying.
		 */
		if (retval < 0 || !iov_iter_count(iter) || *ppos >= size ||
		    IS_DAX(inode)) {
			file_accessed(file);
			goto out;
		}
	}

	retval = do_generic_file_read(file, ppos, iter, retval);
out:
	return retval;
}
EXPORT_SYMBOL(generic_file_read_iter);
```