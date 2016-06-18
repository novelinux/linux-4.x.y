__mnt_want_write
========================================

comments
----------------------------------------

path: fs/namespace.c
```
/*
 * Most r/o & frozen checks on a fs are for operations that take discrete
 * amounts of time, like a write() or unlink().  We must keep track of when
 * those operations start (for permission checks) and when they end, so that we
 * can determine when writes are able to occur to a filesystem.
 */
/**
 * __mnt_want_write - get write access to a mount without freeze protection
 * @m: the mount on which to take a write
 *
 * This tells the low-level filesystem that a write is about to be performed to
 * it, and makes sure that writes are allowed (mnt it read-write) before
 * returning success. This operation does not protect against filesystem being
 * frozen. When the write operation is finished, __mnt_drop_write() must be
 * called. This is effectively a refcount.
 */
```

Arguments
----------------------------------------

```
int __mnt_want_write(struct vfsmount *m)
{
    struct mount *mnt = real_mount(m);
    int ret = 0;

    preempt_disable();
    mnt_inc_writers(mnt);
    /*
     * The store to mnt_inc_writers must be visible before we pass
     * MNT_WRITE_HOLD loop below, so that the slowpath can see our
     * incremented count after it has set MNT_WRITE_HOLD.
     */
    smp_mb();
    while (ACCESS_ONCE(mnt->mnt.mnt_flags) & MNT_WRITE_HOLD)
        cpu_relax();
    /*
     * After the slowpath clears MNT_WRITE_HOLD, mnt_is_readonly will
     * be set to match its requirements. So we must not load that until
     * MNT_WRITE_HOLD is cleared.
     */
    smp_rmb();
    if (mnt_is_readonly(m)) {
        mnt_dec_writers(mnt);
        ret = -EROFS;
    }
    preempt_enable();

    return ret;
}
```
