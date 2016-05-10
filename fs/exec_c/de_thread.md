de_thread
========================================

Source
----------------------------------------

path: fs/exec.c
```
/*
 * This function makes sure the current process has its own signal table,
 * so that flush_signal_handlers can later reset the handlers without
 * disturbing other processes.  (Other processes might share the signal
 * table via the CLONE_SIGHAND option to clone().)
 */
static int de_thread(struct task_struct *tsk)
{
    struct signal_struct *sig = tsk->signal;
    struct sighand_struct *oldsighand = tsk->sighand;
    spinlock_t *lock = &oldsighand->siglock;

    if (thread_group_empty(tsk))
        goto no_thread_group;

    /*
     * Kill all other threads in the thread group.
     */
    spin_lock_irq(lock);
    if (signal_group_exit(sig)) {
        /*
         * Another group action in progress, just
         * return so that the signal is processed.
         */
        spin_unlock_irq(lock);
        return -EAGAIN;
    }

    sig->group_exit_task = tsk;
    sig->notify_count = zap_other_threads(tsk);
    if (!thread_group_leader(tsk))
        sig->notify_count--;

    while (sig->notify_count) {
        __set_current_state(TASK_KILLABLE);
        spin_unlock_irq(lock);
        schedule();
        if (unlikely(__fatal_signal_pending(tsk)))
            goto killed;
        spin_lock_irq(lock);
    }
    spin_unlock_irq(lock);

    /*
     * At this point all other threads have exited, all we have to
     * do is to wait for the thread group leader to become inactive,
     * and to assume its PID:
     */
    if (!thread_group_leader(tsk)) {
        struct task_struct *leader = tsk->group_leader;

        sig->notify_count = -1;    /* for exit_notify() */
        for (;;) {
            threadgroup_change_begin(tsk);
            write_lock_irq(&tasklist_lock);
            if (likely(leader->exit_state))
                break;
            __set_current_state(TASK_KILLABLE);
            write_unlock_irq(&tasklist_lock);
            threadgroup_change_end(tsk);
            schedule();
            if (unlikely(__fatal_signal_pending(tsk)))
                goto killed;
        }

        /*
         * The only record we have of the real-time age of a
         * process, regardless of execs it's done, is start_time.
         * All the past CPU time is accumulated in signal_struct
         * from sister threads now dead.  But in this non-leader
         * exec, nothing survives from the original leader thread,
         * whose birth marks the true age of this process now.
         * When we take on its identity by switching to its PID, we
         * also take its birthdate (always earlier than our own).
         */
        tsk->start_time = leader->start_time;
        tsk->real_start_time = leader->real_start_time;

        BUG_ON(!same_thread_group(leader, tsk));
        BUG_ON(has_group_leader_pid(tsk));
        /*
         * An exec() starts a new thread group with the
         * TGID of the previous thread group. Rehash the
         * two threads with a switched PID, and release
         * the former thread group leader:
         */

        /* Become a process group leader with the old leader's pid.
         * The old leader becomes a thread of the this thread group.
         * Note: The old leader also uses this pid until release_task
         *       is called.  Odd but simple and correct.
         */
        tsk->pid = leader->pid;
        change_pid(tsk, PIDTYPE_PID, task_pid(leader));
        transfer_pid(leader, tsk, PIDTYPE_PGID);
        transfer_pid(leader, tsk, PIDTYPE_SID);

        list_replace_rcu(&leader->tasks, &tsk->tasks);
        list_replace_init(&leader->sibling, &tsk->sibling);

        tsk->group_leader = tsk;
        leader->group_leader = tsk;

        tsk->exit_signal = SIGCHLD;
        leader->exit_signal = -1;

        BUG_ON(leader->exit_state != EXIT_ZOMBIE);
        leader->exit_state = EXIT_DEAD;

        /*
         * We are going to release_task()->ptrace_unlink() silently,
         * the tracer can sleep in do_wait(). EXIT_DEAD guarantees
         * the tracer wont't block again waiting for this thread.
         */
        if (unlikely(leader->ptrace))
            __wake_up_parent(leader, leader->parent);
        write_unlock_irq(&tasklist_lock);
        threadgroup_change_end(tsk);

        release_task(leader);
    }

    sig->group_exit_task = NULL;
    sig->notify_count = 0;

no_thread_group:
    /* we have changed execution domain */
    tsk->exit_signal = SIGCHLD;

    exit_itimers(sig);
    flush_itimer_signals();

    if (atomic_read(&oldsighand->count) != 1) {
        struct sighand_struct *newsighand;
        /*
         * This ->sighand is shared with the CLONE_SIGHAND
         * but not CLONE_THREAD task, switch to the new one.
         */
        newsighand = kmem_cache_alloc(sighand_cachep, GFP_KERNEL);
        if (!newsighand)
            return -ENOMEM;

        atomic_set(&newsighand->count, 1);
        memcpy(newsighand->action, oldsighand->action,
               sizeof(newsighand->action));

        write_lock_irq(&tasklist_lock);
        spin_lock(&oldsighand->siglock);
        rcu_assign_pointer(tsk->sighand, newsighand);
        spin_unlock(&oldsighand->siglock);
        write_unlock_irq(&tasklist_lock);

        __cleanup_sighand(oldsighand);
    }

    BUG_ON(!thread_group_leader(tsk));
    return 0;

killed:
    /* protects against exit_notify() and __exit_signal() */
    read_lock(&tasklist_lock);
    sig->group_exit_task = NULL;
    sig->notify_count = 0;
    read_unlock(&tasklist_lock);
    return -EAGAIN;
}
```