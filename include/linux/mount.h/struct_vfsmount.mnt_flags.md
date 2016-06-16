mnt_flags
========================================

path: include/linux/mount.h
```
#define MNT_NOSUID     0x01
#define MNT_NODEV      0x02
#define MNT_NOEXEC     0x04
#define MNT_NOATIME    0x08
#define MNT_NODIRATIME 0x10
#define MNT_RELATIME   0x20
#define MNT_READONLY   0x40    /* does the user want this to be r/o? */

#define MNT_SHRINKABLE 0x100
#define MNT_WRITE_HOLD 0x200

#define MNT_SHARED    0x1000    /* if the vfsmount is a shared mount */
#define MNT_UNBINDABLE    0x2000    /* if the vfsmount is a unbindable mount */
/*
 * MNT_SHARED_MASK is the set of flags that should be cleared when a
 * mount becomes shared.  Currently, this is only the flag that says a
 * mount cannot be bind mounted, since this is how we create a mount
 * that shares events with another mount.  If you add a new MNT_*
 * flag, consider how it interacts with shared mounts.
 */
#define MNT_SHARED_MASK    (MNT_UNBINDABLE)
#define MNT_USER_SETTABLE_MASK  (MNT_NOSUID | MNT_NODEV | MNT_NOEXEC \
                 | MNT_NOATIME | MNT_NODIRATIME | MNT_RELATIME \
                 | MNT_READONLY)
#define MNT_ATIME_MASK (MNT_NOATIME | MNT_NODIRATIME | MNT_RELATIME )

#define MNT_INTERNAL_FLAGS (MNT_SHARED | MNT_WRITE_HOLD | MNT_INTERNAL | \
                MNT_DOOMED | MNT_SYNC_UMOUNT | MNT_MARKED)
```