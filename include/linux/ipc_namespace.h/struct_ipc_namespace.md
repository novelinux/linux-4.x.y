struct ipc_namespace
========================================

path: include/linux/ipc_namespace.h
```
struct ipc_namespace {
    atomic_t    count;
    struct ipc_ids    ids[3];

    int        sem_ctls[4];
    int        used_sems;

    unsigned int    msg_ctlmax;
    unsigned int    msg_ctlmnb;
    unsigned int    msg_ctlmni;
    atomic_t    msg_bytes;
    atomic_t    msg_hdrs;

    size_t        shm_ctlmax;
    size_t        shm_ctlall;
    unsigned long    shm_tot;
    int        shm_ctlmni;
    /*
     * Defines whether IPC_RMID is forced for _all_ shm segments regardless
     * of shmctl()
     */
    int        shm_rmid_forced;

    struct notifier_block ipcns_nb;

    /* The kern_mount of the mqueuefs sb.  We take a ref on it */
    struct vfsmount    *mq_mnt;

    /* # queues in this ns, protected by mq_lock */
    unsigned int    mq_queues_count;

    /* next fields are set through sysctl */
    unsigned int    mq_queues_max;   /* initialized to DFLT_QUEUESMAX */
    unsigned int    mq_msg_max;      /* initialized to DFLT_MSGMAX */
    unsigned int    mq_msgsize_max;  /* initialized to DFLT_MSGSIZEMAX */
    unsigned int    mq_msg_default;
    unsigned int    mq_msgsize_default;

    /* user_ns which owns the ipc ns */
    struct user_namespace *user_ns;

    struct ns_common ns;
};
```
