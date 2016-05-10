filemap_fault
========================================

filemap_fault函数的主要作用是，在应用程序访问映射区域但对应数据不在物理内存时调用，
filemap_fault借助于潜在的文件系统的底层例程取得所需数据，并读取到物理内存，这些对
应用程序是透明的.换句话说，映射数据不是在建立映射时立即读入内存，只有时机需要时才
进行读取，具体实现如下所示:

path: mm/filemap.c
```
/**
 * filemap_fault - read in file data for page fault handling
 * @vma:    vma in which the fault was taken
 * @vmf:    struct vm_fault containing details of the fault
 *
 * filemap_fault() is invoked via the vma operations vector for a
 * mapped memory region to read in file data during a page fault.
 *
 * The goto's are kind of ugly, but this streamlines the normal case of having
 * it in the page cache, and handles the special cases reasonably without
 * having a lot of duplicated code.
 *
 * vma->vm_mm->mmap_sem must be held on entry.
 *
 * If our return value has VM_FAULT_RETRY set, it's because
 * lock_page_or_retry() returned 0.
 * The mmap_sem has usually been released in this case.
 * See __lock_page_or_retry() for the exception.
 *
 * If our return value does not have VM_FAULT_RETRY set, the mmap_sem
 * has not been released.
 *
 * We never return with VM_FAULT_RETRY and a bit from VM_FAULT_ERROR set.
 */
int filemap_fault(struct vm_area_struct *vma, struct vm_fault *vmf)
{
    int error;
    struct file *file = vma->vm_file;
    struct address_space *mapping = file->f_mapping;
    struct file_ra_state *ra = &file->f_ra;
    struct inode *inode = mapping->host;
    pgoff_t offset = vmf->pgoff;
    struct page *page;
    loff_t size;
    int ret = 0;

    size = round_up(i_size_read(inode), PAGE_CACHE_SIZE);
    if (offset >= size >> PAGE_CACHE_SHIFT)
        return VM_FAULT_SIGBUS;

    /*
     * Do we have something in the page cache already?
     */
    page = find_get_page(mapping, offset);
    if (likely(page) && !(vmf->flags & FAULT_FLAG_TRIED)) {
        /*
         * We found the page, so try async readahead before
         * waiting for the lock.
         */
        do_async_mmap_readahead(vma, ra, file, page, offset);
    } else if (!page) {
        /* No page in the page cache at all */
        do_sync_mmap_readahead(vma, ra, file, offset);
        count_vm_event(PGMAJFAULT);
        mem_cgroup_count_vm_event(vma->vm_mm, PGMAJFAULT);
        ret = VM_FAULT_MAJOR;
retry_find:
        page = find_get_page(mapping, offset);
        if (!page)
            goto no_cached_page;
    }

    if (!lock_page_or_retry(page, vma->vm_mm, vmf->flags)) {
        page_cache_release(page);
        return ret | VM_FAULT_RETRY;
    }

    /* Did it get truncated? */
    if (unlikely(page->mapping != mapping)) {
        unlock_page(page);
        put_page(page);
        goto retry_find;
    }
    VM_BUG_ON_PAGE(page->index != offset, page);

    /*
     * We have a locked page in the page cache, now we need to check
     * that it's up-to-date. If not, it is going to be due to an error.
     */
    if (unlikely(!PageUptodate(page)))
        goto page_not_uptodate;

    /*
     * Found the page and have a reference on it.
     * We must recheck i_size under page lock.
     */
    size = round_up(i_size_read(inode), PAGE_CACHE_SIZE);
    if (unlikely(offset >= size >> PAGE_CACHE_SHIFT)) {
        unlock_page(page);
        page_cache_release(page);
        return VM_FAULT_SIGBUS;
    }

    vmf->page = page;
    return ret | VM_FAULT_LOCKED;

no_cached_page:
    /*
     * We're only likely to ever get here if MADV_RANDOM is in
     * effect.
     */
    error = page_cache_read(file, offset);

    /*
     * The page we want has now been added to the page cache.
     * In the unlikely event that someone removed it in the
     * meantime, we'll just come back here and read it again.
     */
    if (error >= 0)
        goto retry_find;

    /*
     * An error return from page_cache_read can result if the
     * system is low on memory, or a problem occurs while trying
     * to schedule I/O.
     */
    if (error == -ENOMEM)
        return VM_FAULT_OOM;
    return VM_FAULT_SIGBUS;

page_not_uptodate:
    /*
     * Umm, take care of errors if the page isn't up-to-date.
     * Try to re-read it _once_. We do this synchronously,
     * because there really aren't any performance issues here
     * and we need to check for errors.
     */
    ClearPageError(page);
    error = mapping->a_ops->readpage(file, page);
    if (!error) {
        wait_on_page_locked(page);
        if (!PageUptodate(page))
            error = -EIO;
    }
    page_cache_release(page);

    if (!error || error == AOP_TRUNCATED_PAGE)
        goto retry_find;

    /* Things didn't work out. Return zero to tell the mm layer so. */
    shrink_readahead_size_eio(file, ra);
    return VM_FAULT_SIGBUS;
}
EXPORT_SYMBOL(filemap_fault);
```