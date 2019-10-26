## do_generic_file_read

do_generic_file_read()函数的实现在mm/filemap.c文件中,主要功能是从磁盘上读取请求的页面,然后将数据拷贝到用户空间缓冲区中。注释也作了说明,该函数是通用文件读例程,真正执行读操作,是通过mapping->a_ops->readpage()来完成。

```
/**
 * do_generic_file_read - generic file read routine
 * @filp:	the file to read
 * @ppos:	current file position
 * @iter:	data destination
 * @written:	already copied
 *
 * This is a generic file read routine, and uses the
 * mapping->a_ops->readpage() function for the actual low-level stuff.
 *
 * This is really ugly. But the goto's actually try to clarify some
 * of the logic when it comes to error handling etc.
 */
static ssize_t do_generic_file_read(struct file *filp, loff_t *ppos,
		struct iov_iter *iter, ssize_t written)
{
	struct address_space *mapping = filp->f_mapping;
	struct inode *inode = mapping->host;
	struct file_ra_state *ra = &filp->f_ra;
	pgoff_t index;
	pgoff_t last_index;
	pgoff_t prev_index;
	unsigned long offset;      /* offset into pagecache page */
	unsigned int prev_offset;
	int error = 0;

	index = *ppos >> PAGE_CACHE_SHIFT;
	prev_index = ra->prev_pos >> PAGE_CACHE_SHIFT;
	prev_offset = ra->prev_pos & (PAGE_CACHE_SIZE-1);
	last_index = (*ppos + iter->count + PAGE_CACHE_SIZE-1) >> PAGE_CACHE_SHIFT;
	offset = *ppos & ~PAGE_CACHE_MASK;
```

获取文件address_space对象:mapping = filep->f_mapping。获取address_space数据结构的拥有者,也就是inode对象,它的地址保存在address_space对象中的host成员变量中;inode对象拥有用来存储读取数据的页面。
获取预读状态ra: ra = &filp->f_ra,记录预读状态。内核从磁盘上读取文件数据,实际上是以页面大小(4096字节)为单位的;即使用户进程只读1字节,内核每次仍然会至少读取4096字节(若文件本身小于4K怎么办?)宏PAGE_CACHE_SHIFT的值为12,PAGE_CACHE_SIZE的大小就是一个页面大小(4096字节),PAGE_CACHE_MASK的值为~(PAGE_SIZE-1)。
将文件理解成分为多个页面;由前面的解释,我们就不难理解,计算将要读取的数据起始位置index和结束位置last_index所在文件中的页偏移。要读取数据第1字节不一定是和页面对齐的,所以用临时变量offset记录读取的第一个字节在文件页面内的偏移量。

### cond_resched

```
	for (;;) {
		struct page *page;
		pgoff_t end_index;
		loff_t isize;
		unsigned long nr, ret;

		cond_resched();
```

检查当前进程TIF_NEED_RESCHED标志,确定是否需要调度;若设置了该标志,则调度schedule()进行进程调度。

### find_page


```
find_page:
		if (fatal_signal_pending(current)) {
			error = -EINTR;
			goto out;
		}

		page = find_get_page(mapping, index);
		if (!page) {
			page_cache_sync_readahead(mapping,
					ra, filp,
					index, last_index - index);
			page = find_get_page(mapping, index);
			if (unlikely(page == NULL))
				goto no_cached_page;
		}
```

用户读取文件数据,使用之后,内核不会立即将数据丢弃;而是将数据缓存在内核里。进程再次请求该数据时,就会直接返回给用户,不必再从磁盘上读取;这样可以大大提高效率。find_get_page ()就是查找请求的数据是否已经在内核缓冲区中。如果返回值为NULL,则说明此页不在高速缓存中,那么它将执行以下步骤:
* (1)page_cache_sync_readahead(),这个函数会在cache未命中时被调用,它将提交预读请求,修改ra参数,当然也会相应的去预读一些页。
* (2)再次去高速缓存中查找(上一步的预取可能已经将其读到cache中),若果没有找到,那么说明所请求的数据确实不在cache中,就跳到no_cached_page

### PageReadahead

```
		if (PageReadahead(page)) {
			page_cache_async_readahead(mapping,
					ra, filp, page,
					index, last_index - index);
		}
		if (!PageUptodate(page)) {
			/*
			 * See comment in do_read_cache_page on why
			 * wait_on_page_locked is used to avoid unnecessarily
			 * serialisations and why it's safe.
			 */
			wait_on_page_locked_killable(page);
			if (PageUptodate(page))
				goto page_ok;

			if (inode->i_blkbits == PAGE_CACHE_SHIFT ||
					!mapping->a_ops->is_partially_uptodate)
				goto page_not_up_to_date;
			if (!trylock_page(page))
				goto page_not_up_to_date;
			/* Did it get truncated before we got the lock? */
			if (!page->mapping)
				goto page_not_up_to_date_locked;
			if (!mapping->a_ops->is_partially_uptodate(page,
							offset, iter->count))
				goto page_not_up_to_date_locked;
			unlock_page(page);
		}
```

说明所请求数据已在高速缓存中,那么此时判断它是否为readahead页,如果是,则发起异步预读请求page_cache_async_readahead(),这个函数在page有PG_readahead字段时才被调用,意味着已经用光了足够的readahead window中的page,我们需要添加更多的page到预读窗口。

接着判断此页的PG_uptodate位,如果被置位,则说明页中所存数据是最新的,因此无需从磁盘读数据,跳到page_ok处。

mapping->a_ops->is_partially_uptodate()检查页面中的buffer是否都处于update状态。当文件或者设备映射到内存中时,它们的inode结构就会和address_space相关联。当页面属于一个文件时,page->mapping就会指向这个地址空间。如果这个页面是匿名的且映射开启,则address_space就是swapper_space,swapper_space是管理交换地址空间的。若页面不是最新的,说明页中的数据无效:
* (1)若mapping->a_ops->is_partially_uptodate是NULL,或者trylock_page(page)是NULL,那么跳到page_not_up_to_date。
* (2)若文件页面还没建立映射或者页面中的buffer不都是update状态,则跳转到page_not_up_to_date_locked)。
* (3)前面没有跳转的话,说明页面是PG_uptodate状态,通过unlock_page()解锁页面。

### page_ok

```
page_ok:
		/*
		 * i_size must be checked after we know the page is Uptodate.
		 *
		 * Checking i_size after the check allows us to calculate
		 * the correct value for "nr", which means the zero-filled
		 * part of the page is not copied back to userspace (unless
		 * another truncate extends the file - this is desired though).
		 */

		isize = i_size_read(inode);
		end_index = (isize - 1) >> PAGE_CACHE_SHIFT;
		if (unlikely(!isize || index > end_index)) {
			page_cache_release(page);
			goto out;
		}

		/* nr is the maximum number of bytes to copy from this page */
		nr = PAGE_CACHE_SIZE;
		if (index == end_index) {
			nr = ((isize - 1) & ~PAGE_CACHE_MASK) + 1;
			if (nr <= offset) {
				page_cache_release(page);
				goto out;
			}
		}
		nr = nr - offset;

		/* If users can be writing to this page using arbitrary
		 * virtual addresses, take care about potential aliasing
		 * before reading the page on the kernel side.
		 */
		if (mapping_writably_mapped(mapping))
			flush_dcache_page(page);

		/*
		 * When a sequential read accesses a page several times,
		 * only mark it as accessed the first time.
		 */
		if (prev_index != index || offset != prev_offset)
			mark_page_accessed(page);
		prev_index = index;

		/*
		 * Ok, we have the page, and it's up-to-date, so
		 * now we can copy it to user space...
		 */

		ret = copy_page_to_iter(page, offset, nr, iter);
		offset += ret;
		index += offset >> PAGE_CACHE_SHIFT;
		offset &= ~PAGE_CACHE_MASK;
		prev_offset = offset;

		page_cache_release(page);
		written += ret;
		if (!iov_iter_count(iter))
			goto out;
		if (ret < nr) {
			error = -EFAULT;
			goto out;
		}
		continue;
```

page_ok总是会被执行,即使页面不在Cache中,从磁盘读取数据,之后也会跳转page_ok处.首先检查文件大小,也就是index * 4096是否超过i_size,如果超过,则减少page的计数器,并且跳转到out处。设置nr大小,nr是从此页可读取的最大字节数,就是向用户缓冲区拷贝的字节数。之后就跳转到page_ok标号处。通常的页是4KB,但是对于文件的最后一页,可能不足4KB,所以要进行调整。

如果用户使用不正常的虚拟地址写这个页,要flush_dcache_page(),将dcache相应的page里的数据写到memory里去,以保证dcache内的数据与memory内的数据的一致性。但在x86架构中,flush_dcache_page()的实现为空,不做任何操作。

调用make_page_accessed()设置页面的PG_active和PG_referenced标志,表示页面正在被使用且不能被调换(swap)出去。若同样的页面被do_generic_file_read ()多次读,这一步仅在第一次读时执行(即offset为0)。

将已读取到的数据拷贝到用户空间的缓冲区中,调用的是copy_page_to_iter函数,稍后我们再仔细分析这个函数。数据拷贝到用户空间的缓冲区后,更新局部变量offset和index的值,递减页面计数)。若iov_iter_count的count值不为0,说明还有其他文件数据需要读,for循环不退出,重新从开始执行,进行下一轮读。

### page_not_up_to_date

```
page_not_up_to_date:
		/* Get exclusive access to the page ... */
		error = lock_page_killable(page);
		if (unlikely(error))
			goto readpage_error;
```

lock_page_killable(),给page加锁,这个过程可以被中断的,如果加锁失败,则跳到readpage_error,否则跳转到page_not_up_to_date_locked。

### page_not_up_to_date_locked

```
page_not_up_to_date_locked:
		/* Did it get truncated before we got the lock? */
		if (!page->mapping) {
			unlock_page(page);
			page_cache_release(page);
			continue;
		}

		/* Did somebody else fill it already? */
		if (PageUptodate(page)) {
			unlock_page(page);
			goto page_ok;
		}
```

* (1)如果在获取锁之前就此页已经被truncated,释放锁,减少页的计数,结束本次循环,进入下一次循环。
* (2)否则,它没有被truncated,如果它已经被填充(已从磁盘上读取),那么解锁,并且跳转到page_ok。

### read_page

```
readpage:
		/*
		 * A previous I/O error may have been due to temporary
		 * failures, eg. multipath errors.
		 * PG_error will be set again if readpage fails.
		 */
		ClearPageError(page);
		/* Start the actual read. The read will unlock the page. */
		error = mapping->a_ops->readpage(filp, page);

		if (unlikely(error)) {
			if (error == AOP_TRUNCATED_PAGE) {
				page_cache_release(page);
				error = 0;
				goto find_page;
			}
			goto readpage_error;
		}

		if (!PageUptodate(page)) {
			error = lock_page_killable(page);
			if (unlikely(error))
				goto readpage_error;
			if (!PageUptodate(page)) {
				if (page->mapping == NULL) {
					/*
					 * invalidate_mapping_pages got it
					 */
					unlock_page(page);
					page_cache_release(page);
					goto find_page;
				}
				unlock_page(page);
				shrink_readahead_size_eio(filp, ra);
				error = -EIO;
				goto readpage_error;
			}
			unlock_page(page);
		}

		goto page_ok;
```

真正执行从磁盘读数据的过程。其实真正执行从磁盘读数据的操作就是调用文件的address_space对象readpage ()方法,对于ext4文件系统来说,readpage方法实现都是函数ext4_readpage(),这个函数仅是对mpage_readpage()简单封装。从函数名就可以看出,该函数一次只读一个页面,显然对于内核来说这种情形是很少有的,大部分是一次读取多个页面,也就是预读(一次读多个页面)。对于do_generic_file_read()来说,执行最多的路径是执行page_cache_sync_readahead()和page_cache_async_readahead()。

[ext4 readpage](../../fs/ext4/inode.c/ext4_aops.md)

mapping->a_ops->readpage(),如果读取失败,error返回值不为0,再进一步判断error是AOP_TRUNCATED_PAGE时,则减少计数,跳到find_page,如果不是此error,那么跳到readpage_error。

若页面没有被设置PG_uptodate标志位,即页中的数据不是最新的,那么给页加锁,如果加锁失败,则跳到readpage_error。加锁成功则再次判断他的PG_uptodate位,如果仍然没有被置位,再判断page的mapping是不是为空,若为空,则解锁并且减少page计数,然后跳到find_page。如果mapping不为空,则调整ra,并跳到readpage_error。

经常以上判断检查后,说明页中的数据是最新的,那么跳到page_ok.

### readpage_error


```
readpage_error:
		/* UHHUH! A synchronous read error occurred. Report it */
		page_cache_release(page);
		goto out;
```

到此步骤,说明同步read出错,报告这个错误,并且跳出循环,即跳到out。

### no_cached_page

```
no_cached_page:
		/*
		 * Ok, it wasn't cached, so we need to create a new
		 * page..
		 */
		page = page_cache_alloc_cold(mapping);
		if (!page) {
			error = -ENOMEM;
			goto out;
		}
		error = add_to_page_cache_lru(page, mapping, index,
				mapping_gfp_constraint(mapping, GFP_KERNEL));
		if (error) {
			page_cache_release(page);
			if (error == -EEXIST) {
				error = 0;
				goto find_page;
			}
			goto out;
		}
		goto readpage;
	}
```

### out

分配一个新页:page_cache_alloc_cold(),然后添加到cache的lru上, add_to_page_cache_lru(),跳到readpage。

这里,我们就可以回答本文概述中的一个问题:“内核是在哪个地方分配空间来存储将要读取的数据?”。

答案是,在do_generic_file_read()函数中,此时内存缓存中没有要请求的数据。这里提醒一下,read()的一个参数buf,其缓冲区是在用户空间的,大小与页面大小无关。而page_cache_alloc_cold分配的空间是在内核中,且大小是以页面大小为单位。

```
out:
	ra->prev_pos = prev_index;
	ra->prev_pos <<= PAGE_CACHE_SHIFT;
	ra->prev_pos |= prev_offset;

	*ppos = ((loff_t)index << PAGE_CACHE_SHIFT) + offset;
	file_accessed(filp);
	return written ? written : error;
}
```

所请求或者可提供的字节已经被读取,更新filp->f_ra提前读数据结构。然后更新*ppos的值,也就是更新当前文件读写位置;编程中经常使用read()、write()的话,不难理解ppos的值。最后调用file_accessed()来更新文件inode节点中i_atime的时间为当前时间,且将inode标记为脏。至此,do_generic_file_read()函数执行完毕。

### 读进程的阻塞和继续执行过程

当内核将读请求发到磁盘控制器驱动的请求队列中,显然将请求放入队列中后,用户进程请求的数据并没有立即读到内核空间和用户缓冲区中。将读请求放入队列中后,sys_read()执行结束,并返回到用户空间?用户进程读数据时,是否会有阻塞过程?

将请求放入队列后,read ()系统调用并没有立即从内核空间返回到用户空间。因为请求的数据还没有读到内存中,就不能返回到用户空间,一旦返回到用户空间,用户进程就可以随时访问,可此时用户缓冲区中还没有请求的数据呢,又如何能访问?

将请求放到块设备(磁盘)的请求队列上后,用户进程就会阻塞,直到所请求的数据就绪为止。

读文件数据大多数情况下都是通过预读的,也就是执行page_cache_sync_readahead()或page_cache_async_readahead ()。该函数中完成了将数据请求放到块设备队列上去,然后该函数就执行结束了,但请求的数据并不会那么快已读到内存中。

执行预读后,通过find_get_page()再次查找所请求的页面是否在缓冲区中,经过预读后,页面已经在缓冲区中。因为请求的数据还未就绪,那么页面得PG_update标志就没有被设置,就会跳转到page_not_up_to_date标号处。

进程的阻塞正是在lock_page_killable()inline函数中,当请求的数据读到内存中后,lock_page_killable()才会执行完毕,

[]