struct user_namespace
========================================

path: include/linux/user_namespace.h
```
struct user_namespace {
    struct uid_gid_map    uid_map;
    struct uid_gid_map    gid_map;
    struct uid_gid_map    projid_map;
    atomic_t              count;
    struct user_namespace *parent;
    int                   level;
    kuid_t                owner;
    kgid_t                group;
    struct ns_common      ns;
    unsigned long         flags;

    /* Register of per-UID persistent keyrings for this namespace */
#ifdef CONFIG_PERSISTENT_KEYRINGS
    struct key        *persistent_keyring_register;
    struct rw_semaphore    persistent_keyring_register_sem;
#endif
};
```