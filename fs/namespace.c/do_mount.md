do_mount
========================================

Arguments
----------------------------------------

path: fs/namespace.c
```
/*
 * Flags is a 32-bit value that allows up to 31 non-fs dependent flags to
 * be given to the mount() call (ie: read-only, no-dev, no-suid etc).
 *
 * data is a (void *) that can point to any structure up to
 * PAGE_SIZE-1 bytes, which can contain arbitrary fs-dependent
 * information (or be NULL).
 *
 * Pre-0.97 versions of mount() didn't have a flags word.
 * When the flags word was introduced its top half was required
 * to have the magic value 0xC0ED, and this remained so until 2.4.0-test9.
 * Therefore, if this magic number is present, it carries no information
 * and must be discarded.
 */
long do_mount(const char *dev_name, const char __user *dir_name,
        const char *type_page, unsigned long flags, void *data_page)
{
    struct path path;
    int retval = 0;
    int mnt_flags = 0;

    /* Discard magic */
    if ((flags & MS_MGC_MSK) == MS_MGC_VAL)
        flags &= ~MS_MGC_MSK;

    /* Basic sanity checks */
    if (data_page)
        ((char *)data_page)[PAGE_SIZE - 1] = 0;

    /* ... and get the mountpoint */
    retval = user_path(dir_name, &path);
    if (retval)
        return retval;

    retval = security_sb_mount(dev_name, &path,
                   type_page, flags, data_page);
    if (!retval && !may_mount())
        retval = -EPERM;
    if (retval)
        goto dput_out;

    /* Default to relatime unless overriden */
    if (!(flags & MS_NOATIME))
        mnt_flags |= MNT_RELATIME;

    /* Separate the per-mountpoint flags */
    if (flags & MS_NOSUID)
        mnt_flags |= MNT_NOSUID;
    if (flags & MS_NODEV)
        mnt_flags |= MNT_NODEV;
    if (flags & MS_NOEXEC)
        mnt_flags |= MNT_NOEXEC;
    if (flags & MS_NOATIME)
        mnt_flags |= MNT_NOATIME;
    if (flags & MS_NODIRATIME)
        mnt_flags |= MNT_NODIRATIME;
    if (flags & MS_STRICTATIME)
        mnt_flags &= ~(MNT_RELATIME | MNT_NOATIME);
    if (flags & MS_RDONLY)
        mnt_flags |= MNT_READONLY;

    /* The default atime for remount is preservation */
    if ((flags & MS_REMOUNT) &&
        ((flags & (MS_NOATIME | MS_NODIRATIME | MS_RELATIME |
               MS_STRICTATIME)) == 0)) {
        mnt_flags &= ~MNT_ATIME_MASK;
        mnt_flags |= path.mnt->mnt_flags & MNT_ATIME_MASK;
    }

    flags &= ~(MS_NOSUID | MS_NOEXEC | MS_NODEV | MS_ACTIVE | MS_BORN |
           MS_NOATIME | MS_NODIRATIME | MS_RELATIME| MS_KERNMOUNT |
           MS_STRICTATIME);

    if (flags & MS_REMOUNT)
        retval = do_remount(&path, flags & ~MS_REMOUNT, mnt_flags,
                    data_page);
    else if (flags & MS_BIND)
        retval = do_loopback(&path, dev_name, flags & MS_REC);
    else if (flags & (MS_SHARED | MS_PRIVATE | MS_SLAVE | MS_UNBINDABLE))
        retval = do_change_type(&path, flags);
    else if (flags & MS_MOVE)
        retval = do_move_mount(&path, dev_name);
```

do_new_mount
----------------------------------------

```
    else
        retval = do_new_mount(&path, type_page, flags, mnt_flags,
                      dev_name, data_page);
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/namespace.c/do_new_mount.md

Return
----------------------------------------

```
dput_out:
    path_put(&path);
    return retval;
}
```