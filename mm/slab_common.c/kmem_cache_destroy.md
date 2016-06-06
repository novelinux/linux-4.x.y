kmem_cache_destroy
========================================

如果要销毁只包含未使用对象的一个缓存，则必须调用kmem_cache_destroy函数。该函数主要在删除模块时
调用，此时需要将分配的内存都释放。

path: mm/slab_common.c
```
void kmem_cache_destroy(struct kmem_cache *s)
{
    struct kmem_cache *c, *c2;
    LIST_HEAD(release);
    bool need_rcu_barrier = false;
    bool busy = false;

    if (unlikely(!s))
        return;

    BUG_ON(!is_root_cache(s));

    get_online_cpus();
    get_online_mems();

    mutex_lock(&slab_mutex);

    s->refcount--;
    if (s->refcount)
        goto out_unlock;

    for_each_memcg_cache_safe(c, c2, s) {
        if (do_kmem_cache_shutdown(c, &release, &need_rcu_barrier))
            busy = true;
    }

    if (!busy)
        do_kmem_cache_shutdown(s, &release, &need_rcu_barrier);

out_unlock:
    mutex_unlock(&slab_mutex);

    put_online_mems();
    put_online_cpus();

    do_kmem_cache_release(&release, need_rcu_barrier);
}
EXPORT_SYMBOL(kmem_cache_destroy);
```
