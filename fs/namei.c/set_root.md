set_root
========================================

path: fs/namei.c
```
static void set_root(struct nameidata *nd)
{
    struct fs_struct *fs = current->fs;

    if (nd->flags & LOOKUP_RCU) {
        unsigned seq;

        do {
            seq = read_seqcount_begin(&fs->seq);
            nd->root = fs->root;
            nd->root_seq = __read_seqcount_begin(&nd->root.dentry->d_seq);
        } while (read_seqcount_retry(&fs->seq, seq));
    } else {
        get_fs_root(fs, &nd->root);
    }
}
```