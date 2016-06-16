get_empty_file
========================================

Arguments
----------------------------------------

path: fs/file_table.c
```
/* Find an unused file structure and return a pointer to it.
 * Returns an error pointer if some error happend e.g. we over file
 * structures limit, run out of memory or operation is not permitted.
 *
 * Be very careful using this.  You are responsible for
 * getting write access to any mount that you might assign
 * to this filp, if it is opened for write.  If this is not
 * done, you will imbalance int the mount's writer count
 * and a warning at __fput() time.
 */
struct file *get_empty_filp(void)
{
```

current_cred
----------------------------------------

```
    const struct cred *cred = current_cred();
    static long old_max;
    struct file *f;
    int error;

    /*
     * Privileged users can go above max_files
     */
    if (get_nr_files() >= files_stat.max_files && !capable(CAP_SYS_ADMIN)) {
        /*
         * percpu_counters are inaccurate.  Do an expensive check before
         * we go and fail.
         */
        if (percpu_counter_sum_positive(&nr_files) >= files_stat.max_files)
            goto over;
    }
```

kmem_cache_zalloc
----------------------------------------

为struct file从slab中分配内存.

```
    f = kmem_cache_zalloc(filp_cachep, GFP_KERNEL);
    if (unlikely(!f))
        return ERR_PTR(-ENOMEM);

    percpu_counter_inc(&nr_files);
```

get_cred
----------------------------------------

```
    f->f_cred = get_cred(cred);
    error = security_file_alloc(f);
    if (unlikely(error)) {
        file_free(f);
        return ERR_PTR(error);
    }

    atomic_long_set(&f->f_count, 1);
    rwlock_init(&f->f_owner.lock);
    spin_lock_init(&f->f_lock);
    mutex_init(&f->f_pos_lock);
    eventpoll_init_file(f);
    /* f->f_version: 0 */
    return f;

over:
    /* Ran out of filps - report that */
    if (get_nr_files() > old_max) {
        pr_info("VFS: file-max limit %lu reached\n", get_max_files());
        old_max = get_nr_files();
    }
    return ERR_PTR(-ENFILE);
}
```