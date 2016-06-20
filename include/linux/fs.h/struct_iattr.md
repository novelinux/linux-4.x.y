struct iattr
========================================

path: include/linux/fs.h
```
/*
 * This is the Inode Attributes structure, used for notify_change().  It
 * uses the above definitions as flags, to know which values have changed.
 * Also, in this manner, a Filesystem can look at only the values it cares
 * about.  Basically, these are the attributes that the VFS layer can
 * request to change from the FS layer.
 *
 * Derek Atkins <warlord@MIT.EDU> 94-10-20
 */
struct iattr {
    unsigned int       ia_valid;
    umode_t            ia_mode;
    kuid_t             ia_uid;
    kgid_t             ia_gid;
    loff_t             ia_size;
    struct timespec    ia_atime;
    struct timespec    ia_mtime;
    struct timespec    ia_ctime;

    /*
     * Not an attribute, but an auxiliary info for filesystems wanting to
     * implement an ftruncate() like method.  NOTE: filesystem should
     * check for (ia_valid & ATTR_FILE), and not for (ia_file != NULL).
     */
    struct file    *ia_file;
};
```