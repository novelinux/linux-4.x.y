ext4_es_lookup_extent
========================================

Arguments
----------------------------------------

path: fs/ext4/extents_status.c
```
/*
 * ext4_es_lookup_extent() looks up an extent in extent status tree.
 *
 * ext4_es_lookup_extent is called by ext4_map_blocks/ext4_da_map_blocks.
 *
 * Return: 1 on found, 0 on not
 */
int ext4_es_lookup_extent(struct inode *inode, ext4_lblk_t lblk,
              struct extent_status *es)
{
    struct ext4_es_tree *tree;
    struct ext4_es_stats *stats;
    struct extent_status *es1 = NULL;
    struct rb_node *node;
    int found = 0;

    trace_ext4_es_lookup_extent_enter(inode, lblk);
    es_debug("lookup extent in block %u\n", lblk);

    tree = &EXT4_I(inode)->i_es_tree;
    read_lock(&EXT4_I(inode)->i_es_lock);

    /* find extent in cache firstly */
    es->es_lblk = es->es_len = es->es_pblk = 0;
    if (tree->cache_es) {
        es1 = tree->cache_es;
        if (in_range(lblk, es1->es_lblk, es1->es_len)) {
            es_debug("%u cached by [%u/%u)\n",
                 lblk, es1->es_lblk, es1->es_len);
            found = 1;
            goto out;
        }
    }

    node = tree->root.rb_node;
    while (node) {
        es1 = rb_entry(node, struct extent_status, rb_node);
        if (lblk < es1->es_lblk)
            node = node->rb_left;
        else if (lblk > ext4_es_end(es1))
            node = node->rb_right;
        else {
            found = 1;
            break;
        }
    }

out:
    stats = &EXT4_SB(inode->i_sb)->s_es_stats;
    if (found) {
        BUG_ON(!es1);
        es->es_lblk = es1->es_lblk;
        es->es_len = es1->es_len;
        es->es_pblk = es1->es_pblk;
        if (!ext4_es_is_referenced(es))
            ext4_es_set_referenced(es);
        stats->es_stats_cache_hits++;
    } else {
        stats->es_stats_cache_misses++;
    }

    read_unlock(&EXT4_I(inode)->i_es_lock);

    trace_ext4_es_lookup_extent_exit(inode, es, found);
    return found;
}
```
