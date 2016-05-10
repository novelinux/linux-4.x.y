prepare_binprm
========================================

file_inode
----------------------------------------

调用file_inode节点获取可执行文件的inode节点信息.

path: fs/exec.c
```
/*
 * Fill the binprm structure from the inode.
 * Check permissions, then read the first 128 (BINPRM_BUF_SIZE) bytes
 *
 * This may be called multiple times for binary chains (scripts for example).
 */
int prepare_binprm(struct linux_binprm *bprm)
{
    struct inode *inode = file_inode(bprm->file);
    umode_t mode = inode->i_mode;
    int retval;
```

检查suid
----------------------------------------

在确认文件来源在读取时没有置位MNT_NOSUID,内核会检测
SUID和SGID是否置位，如果SUID置位的话那么有效UID和inode
相同. SGID类似,如果setgid置位但组执行位没有置位，那么
这可能是强制锁定，而不是setgid的可执行文件.

```
    /* clear any previous set[ug]id data from a previous binary */
    bprm->cred->euid = current_euid();
    bprm->cred->egid = current_egid();

    if (!(bprm->file->f_path.mnt->mnt_flags & MNT_NOSUID) &&
        !task_no_new_privs(current) &&
        kuid_has_mapping(bprm->cred->user_ns, inode->i_uid) &&
        kgid_has_mapping(bprm->cred->user_ns, inode->i_gid)) {
        /* Set-uid? */
        if (mode & S_ISUID) {
            bprm->per_clear |= PER_CLEAR_ON_SETID;
            bprm->cred->euid = inode->i_uid;
        }

        /* Set-gid? */
        /*
         * If setgid is set but no group execute bit then this
         * is a candidate for mandatory locking, not a setgid
         * executable.
         */
        if ((mode & (S_ISGID | S_IXGRP)) == (S_ISGID | S_IXGRP)) {
            bprm->per_clear |= PER_CLEAR_ON_SETID;
            bprm->cred->egid = inode->i_gid;
        }
    }

    /* fill in binprm security blob */
    retval = security_bprm_set_creds(bprm);
    if (retval)
        return retval;
    bprm->cred_prepared = 1;

    memset(bprm->buf, 0, BINPRM_BUF_SIZE);
```

kernel_read
----------------------------------------

读取可执行文件的前128个字节填充bprm的buf字段

```
    return kernel_read(bprm->file, 0, bprm->buf, BINPRM_BUF_SIZE);
}
```
