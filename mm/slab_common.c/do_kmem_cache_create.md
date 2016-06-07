do_kmem_cache_create
========================================

path: mm/slab_common.c
```
static struct kmem_cache *
do_kmem_cache_create(const char *name, size_t object_size, size_t size,
             size_t align, unsigned long flags, void (*ctor)(void *),
             struct mem_cgroup *memcg, struct kmem_cache *root_cache)
{
    struct kmem_cache *s;
    int err;

    err = -ENOMEM;
    s = kmem_cache_zalloc(kmem_cache, GFP_KERNEL);
    if (!s)
        goto out;

    s->name = name;
    s->object_size = object_size;
    s->size = size;
    s->align = align;
    s->ctor = ctor;

    err = init_memcg_params(s, memcg, root_cache);
    if (err)
        goto out_free_cache;

    err = __kmem_cache_create(s, flags);
    if (err)
        goto out_free_cache;

    s->refcount = 1;
    list_add(&s->list, &slab_caches);
out:
    if (err)
        return ERR_PTR(err);
    return s;

out_free_cache:
    destroy_memcg_params(s);
    kmem_cache_free(kmem_cache, s);
    goto out;
}
```