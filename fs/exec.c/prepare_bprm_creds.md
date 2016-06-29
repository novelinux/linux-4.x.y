prepare_bprm_creds
========================================

path: fs/exec.c
```
/*
 * Prepare credentials and lock ->cred_guard_mutex.
 * install_exec_creds() commits the new creds and drops the lock.
 * Or, if exec fails before, free_bprm() should release ->cred and
 * and unlock.
 */
int prepare_bprm_creds(struct linux_binprm *bprm)
{
    if (mutex_lock_interruptible(&current->signal->cred_guard_mutex))
        return -ERESTARTNOINTR;

    bprm->cred = prepare_exec_creds();
    if (likely(bprm->cred))
        return 0;

    mutex_unlock(&current->signal->cred_guard_mutex);
    return -ENOMEM;
}
```