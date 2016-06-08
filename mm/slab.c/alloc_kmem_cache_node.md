alloc_kmem_cache_node
========================================

Arguments
----------------------------------------

path: mm/slab.c
```
/*
 * This initializes kmem_cache_node or resizes various caches for all nodes.
 */
static int alloc_kmem_cache_node(struct kmem_cache *cachep, gfp_t gfp)
{
    int node;
    struct kmem_cache_node *n;
    struct array_cache *new_shared;
    struct alien_cache **new_alien = NULL;
```

for_each_online_node
----------------------------------------

```
    for_each_online_node(node) {

        if (use_alien_caches) {
            new_alien = alloc_alien_cache(node, cachep->limit, gfp);
            if (!new_alien)
                goto fail;
        }

        new_shared = NULL;
        if (cachep->shared) {
            new_shared = alloc_arraycache(node,
                cachep->shared*cachep->batchcount,
                    0xbaadf00d, gfp);
            if (!new_shared) {
                free_alien_cache(new_alien);
                goto fail;
            }
        }
```

### get_node

```
        n = get_node(cachep, node);
        if (n) {
            struct array_cache *shared = n->shared;
            LIST_HEAD(list);

            spin_lock_irq(&n->list_lock);

            if (shared)
                free_block(cachep, shared->entry,
                        shared->avail, node, &list);

            n->shared = new_shared;
            if (!n->alien) {
                n->alien = new_alien;
                new_alien = NULL;
            }
            n->free_limit = (1 + nr_cpus_node(node)) *
                    cachep->batchcount + cachep->num;
            spin_unlock_irq(&n->list_lock);
            slabs_destroy(cachep, &list);
            kfree(shared);
            free_alien_cache(new_alien);
            continue;
        }
```

### kmalloc_node

```
        n = kmalloc_node(sizeof(struct kmem_cache_node), gfp, node);
        if (!n) {
            free_alien_cache(new_alien);
            kfree(new_shared);
            goto fail;
        }
```

### kmem_cache_node_init

```
        kmem_cache_node_init(n);
        n->next_reap = jiffies + REAPTIMEOUT_NODE +
                ((unsigned long)cachep) % REAPTIMEOUT_NODE;
        n->shared = new_shared;
        n->alien = new_alien;
        n->free_limit = (1 + nr_cpus_node(node)) *
                    cachep->batchcount + cachep->num;
        cachep->node[node] = n;
    }
    return 0;
```

https://github.com/novelinux/linux-4.x.y/blob/master/mm/slab.c/kmem_cache_node_init.md

fail
----------------------------------------

```
fail:
    if (!cachep->list.next) {
        /* Cache is not active yet. Roll back what we did */
        node--;
        while (node >= 0) {
            n = get_node(cachep, node);
            if (n) {
                kfree(n->shared);
                free_alien_cache(n->alien);
                kfree(n);
                cachep->node[node] = NULL;
            }
            node--;
        }
    }
    return -ENOMEM;
}
```