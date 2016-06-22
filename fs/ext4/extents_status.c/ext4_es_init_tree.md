ext4_es_init_tree
========================================

path: fs/ext4/extents_status.c
```
void ext4_es_init_tree(struct ext4_es_tree *tree)
{
    tree->root = RB_ROOT;
    tree->cache_es = NULL;
}
```
