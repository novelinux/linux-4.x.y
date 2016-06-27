sget
========================================

path: fs/super.c
```
struct super_block *sget(struct file_system_type *type,
            int (*test)(struct super_block *,void *),
            int (*set)(struct super_block *,void *),
            int flags,
            void *data)
{
    struct super_block *s = NULL;
    struct super_block *old;
    int err;

retry:
    spin_lock(&sb_lock);
    if (test) {
        hlist_for_each_entry(old, &type->fs_supers, s_instances) {
            if (!test(old, data))
                continue;
            if (!grab_super(old))
                goto retry;
            if (s) {
                up_write(&s->s_umount);
                destroy_super(s);
                s = NULL;
            }
            return old;
        }
    }
    if (!s) {
        spin_unlock(&sb_lock);
        s = alloc_super(type, flags);
        if (!s)
            return ERR_PTR(-ENOMEM);
        goto retry;
    }

    err = set(s, data);
    if (err) {
        spin_unlock(&sb_lock);
        up_write(&s->s_umount);
        destroy_super(s);
        return ERR_PTR(err);
    }
    s->s_type = type;
    strlcpy(s->s_id, type->name, sizeof(s->s_id));
    list_add_tail(&s->s_list, &super_blocks);
    hlist_add_head(&s->s_instances, &type->fs_supers);
    spin_unlock(&sb_lock);
    get_filesystem(type);
    register_shrinker(&s->s_shrink);
    return s;
}
```