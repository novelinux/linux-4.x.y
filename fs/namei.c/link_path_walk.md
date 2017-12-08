# link_path_walk

link_path_walk的流程是一个不断穿过目录层次的过程。

## Arguments

path: fs/namei.c
```
/*
 * Name resolution.
 * This is the basic name resolution function, turning a pathname into
 * the final dentry. We expect 'base' to be positive and a directory.
 *
 * Returns 0 and nd will have valid dentry and mnt on success.
 * Returns error and drops reference to input namei data on failure.
 */
static int link_path_walk(const char *name, struct nameidata *nd)
{
    int err;

    while (*name=='/')
        name++;
    if (!*name)
        return 0;
```

## for

该函数由一个大的循环组成，逐分量处理文件名或路径名。名称在循环内部分解为各个分量（各分量通过
一个或多个斜线分隔）。每个分量表示一个目录名，最后一个分量例外，总是文件名。

在内核遇到一个（或多个）斜线（/）之前，name是逐字符扫描的。斜线会跳过，因为我们只对文件名称
本身感兴趣。例如，如果文件名为/cache/test.txt，那么只有路径的3个分量cache, test.txt是相关的，
斜线应该与路径分量分离开来。每个循环中处理一个路径分量。

```
    /* At this point we know we have a real path component. */
    for(;;) {  /* 把name参数中传递的路径名分解为分量"/"被当做分隔符对于每个分量执行 */
        u64 hash_len;
        int type;

        err = may_lookup(nd);
         if (err)
            return err;

        hash_len = hash_name(name);

        type = LAST_NORM;
        if (name[0] == '.') switch (hashlen_len(hash_len)) {
            case 2:
                if (name[1] == '.') {
                    type = LAST_DOTDOT;
                    nd->flags |= LOOKUP_JUMPED;
                }
                break;
            case 1:
                type = LAST_DOT;
        }
```

### this

```
        if (likely(type == LAST_NORM)) {
            struct dentry *parent = nd->path.dentry;
            nd->flags &= ~LOOKUP_JUMPED;
            if (unlikely(parent->d_flags & DCACHE_OP_HASH)) {
                struct qstr this = { { .hash_len = hash_len }, .name = name };
                err = parent->d_op->d_hash(parent, &this);
                if (err < 0)
                    return err;
                hash_len = this.hash_len;
                name = this.name;
            }
        }

        nd->last.hash_len = hash_len;
        nd->last.name = name;
        nd->last_type = type;

        name += hashlen_len(hash_len);
        if (!*name)
            goto OK;
        /*
         * If it wasn't NUL, we know it was '/'. Skip that
         * slash, and continue until no more slashes.
         */
        do {
            name++;
        } while (unlikely(*name == '/'));
        if (unlikely(!*name)) {
```

### OK

```
OK:
            /* pathname body, done */
            if (!nd->depth)
                return 0;
            name = nd->stack[nd->depth - 1].name;
            /* trailing symlink, done */
            if (!name)
                return 0;
            /* last component of nested symlink */
            err = walk_component(nd, WALK_GET | WALK_PUT);
        } else {
            err = walk_component(nd, WALK_GET);
        }
        if (err < 0)
            return err;

        if (err) {
            const char *s = get_link(nd);

            if (unlikely(IS_ERR(s)))
                return PTR_ERR(s);
            err = 0;
            if (unlikely(!s)) {
                /* jumped */
                put_link(nd);
            } else {
                nd->stack[nd->depth - 1].name = name;
                name = s;
                continue;
            }
        }
        if (unlikely(!d_can_lookup(nd->path.dentry))) {
            if (nd->flags & LOOKUP_RCU) {
                if (unlazy_walk(nd, NULL, 0))
                    return -ECHILD;
            }
            return -ENOTDIR;
        }
    }
}
```
