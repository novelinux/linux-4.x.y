ext4_claim_free_clusters
========================================

path: fs/ext4/balloc.c
```
int ext4_claim_free_clusters(struct ext4_sb_info *sbi,
                 s64 nclusters, unsigned int flags)
{
    if (ext4_has_free_clusters(sbi, nclusters, flags)) {
        percpu_counter_add(&sbi->s_dirtyclusters_counter, nclusters);
        return 0;
    } else
        return -ENOSPC;
}
```

ext4_has_free_clusters
----------------------------------------

https://github.com/novelinux/linux-4.x.y/blob/master/fs/ext4/balloc.c/ext4_has_free_clusters.md
