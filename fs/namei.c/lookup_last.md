lookup_last
========================================

path: fs/namei.c
```
static inline int lookup_last(struct nameidata *nd)
{
    if (nd->last_type == LAST_NORM && nd->last.name[nd->last.len])
        nd->flags |= LOOKUP_FOLLOW | LOOKUP_DIRECTORY;

    nd->flags &= ~LOOKUP_PARENT;
    return walk_component(nd,
            nd->flags & LOOKUP_FOLLOW
                ? nd->depth
                    ? WALK_PUT | WALK_GET
                    : WALK_GET
                : 0);
}
```

walk_component
----------------------------------------

https://github.com/novelinux/linux-4.x.y/blob/master/fs/namei.c/walk_component.md
