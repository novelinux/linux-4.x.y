install_exec_creds
========================================

path: fs/exec.c
```
/*
 * install the new credentials for this executable
 */
void install_exec_creds(struct linux_binprm *bprm)
{
    security_bprm_committing_creds(bprm);

    commit_creds(bprm->cred);
    bprm->cred = NULL;

    /*
     * Disable monitoring for regular users
     * when executing setuid binaries. Must
     * wait until new credentials are committed
     * by commit_creds() above
     */
    if (get_dumpable(current->mm) != SUID_DUMP_USER)
        perf_event_exit_task(current);
    /*
     * cred_guard_mutex must be held at least to this point to prevent
     * ptrace_attach() from altering our determination of the task's
     * credentials; any time after this it may be unlocked.
     */
    security_bprm_committed_creds(bprm);
    mutex_unlock(&current->signal->cred_guard_mutex);
}
EXPORT_SYMBOL(install_exec_creds);
```