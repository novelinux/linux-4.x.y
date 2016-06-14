struct mnt_namespace
========================================

path: fs/mount.h
```
struct mnt_namespace {
       atomic_t         count;
       struct ns_common ns;
       struct mount *   root;
       struct list_head list;
       struct user_namespace    *user_ns;
       u64               seq;    /* Sequence number to prevent loops */
       wait_queue_head_t poll;
       u64 event;
};
```