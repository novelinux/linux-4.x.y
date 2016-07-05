bprm_fill_uid
========================================

Arguments
----------------------------------------

path: fs/exec.c
```
static void bprm_fill_uid(struct linux_binprm *bprm)
{
    struct inode *inode;
    unsigned int mode;
    kuid_t uid;
    kgid_t gid;
```

Set bprm.
----------------------------------------

在确认文件来源在读取时没有置位MNT_NOSUID,内核会检测
SUID和SGID是否置位，如果SUID置位的话那么有效UID和inode
相同. SGID类似,如果setgid置位但组执行位没有置位，那么
这可能是强制锁定，而不是setgid的可执行文件.

```
    /* clear any previous set[ug]id data from a previous binary */
    bprm->cred->euid = current_euid();
    bprm->cred->egid = current_egid();

    if (bprm->file->f_path.mnt->mnt_flags & MNT_NOSUID)
        return;

    if (task_no_new_privs(current))
        return;

    inode = file_inode(bprm->file);
    mode = READ_ONCE(inode->i_mode);
    if (!(mode & (S_ISUID|S_ISGID)))
        return;

    /* Be careful if suid/sgid is set */
    mutex_lock(&inode->i_mutex);

    /* reload atomically mode/uid/gid now that lock held */
    mode = inode->i_mode;
    uid = inode->i_uid;
    gid = inode->i_gid;
    mutex_unlock(&inode->i_mutex);

    /* We ignore suid/sgid if there are no mappings for them in the ns */
    if (!kuid_has_mapping(bprm->cred->user_ns, uid) ||
         !kgid_has_mapping(bprm->cred->user_ns, gid))
        return;

    if (mode & S_ISUID) {
        bprm->per_clear |= PER_CLEAR_ON_SETID;
        bprm->cred->euid = uid;
    }

    if ((mode & (S_ISGID | S_IXGRP)) == (S_ISGID | S_IXGRP)) {
        bprm->per_clear |= PER_CLEAR_ON_SETID;
        bprm->cred->egid = gid;
    }
}
```