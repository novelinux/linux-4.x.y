init_user_ns
========================================

path: kernel/user.c
```
/*
 * userns count is 1 for root user, 1 for init_uts_ns,
 * and 1 for... ?
 */
struct user_namespace init_user_ns = {
    .uid_map = {
        .nr_extents = 1,
        .extent[0] = {
            .first = 0,
            .lower_first = 0,
            .count = 4294967295U,
        },
    },
    .gid_map = {
        .nr_extents = 1,
        .extent[0] = {
            .first = 0,
            .lower_first = 0,
            .count = 4294967295U,
        },
    },
    .projid_map = {
        .nr_extents = 1,
        .extent[0] = {
            .first = 0,
            .lower_first = 0,
            .count = 4294967295U,
        },
    },
    .count = ATOMIC_INIT(3),
    .owner = GLOBAL_ROOT_UID,
    .group = GLOBAL_ROOT_GID,
    .ns.inum = PROC_USER_INIT_INO,
#ifdef CONFIG_USER_NS
    .ns.ops = &userns_operations,
#endif
    .flags = USERNS_INIT_FLAGS,
#ifdef CONFIG_PERSISTENT_KEYRINGS
    .persistent_keyring_register_sem =
    __RWSEM_INITIALIZER(init_user_ns.persistent_keyring_register_sem),
#endif
};
EXPORT_SYMBOL_GPL(init_user_ns);
```