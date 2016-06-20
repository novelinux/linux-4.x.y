do_truncate
========================================

path: fs/open.c
```
int do_truncate(struct dentry *dentry, loff_t length, unsigned int time_attrs,
    struct file *filp)
{
    int ret;
    struct iattr newattrs;

    /* Not pretty: "inode->i_size" shouldn't really be signed. But it is. */
    if (length < 0)
        return -EINVAL;

    newattrs.ia_size = length;
    newattrs.ia_valid = ATTR_SIZE | time_attrs;
    if (filp) {
        newattrs.ia_file = filp;
        newattrs.ia_valid |= ATTR_FILE;
    }

    /* Remove suid, sgid, and file capabilities on truncate too */
    ret = dentry_needs_remove_privs(dentry);
    if (ret < 0)
        return ret;
    if (ret)
        newattrs.ia_valid |= ret | ATTR_FORCE;
```

notify_change
----------------------------------------

```
    mutex_lock(&dentry->d_inode->i_mutex);
    /* Note any delegations or leases have already been broken: */
    ret = notify_change(dentry, &newattrs, NULL);
    mutex_unlock(&dentry->d_inode->i_mutex);
    return ret;
}
```

https://github.com/novelinux/linux-4.x.y/tree/master/fs/attr.c/notify_change.md
