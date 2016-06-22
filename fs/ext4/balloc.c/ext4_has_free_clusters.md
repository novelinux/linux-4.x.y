ext4_has_free_clusters
========================================

path: fs/ext4/balloc.c
```
/**
 * ext4_has_free_clusters()
 * @sbi:       in-core super block structure.
 * @nclusters: number of needed blocks
 * @flags:     flags from ext4_mb_new_blocks()
 *
 * Check if filesystem has nclusters free & available for allocation.
 * On success return 1, return 0 on failure.
 */
static int ext4_has_free_clusters(struct ext4_sb_info *sbi,
                  s64 nclusters, unsigned int flags)
{
    s64 free_clusters, dirty_clusters, rsv, resv_clusters;
    struct percpu_counter *fcc = &sbi->s_freeclusters_counter;
    struct percpu_counter *dcc = &sbi->s_dirtyclusters_counter;

    free_clusters  = percpu_counter_read_positive(fcc);
    dirty_clusters = percpu_counter_read_positive(dcc);
    resv_clusters = atomic64_read(&sbi->s_resv_clusters);

    /*
     * r_blocks_count should always be multiple of the cluster ratio so
     * we are safe to do a plane bit shift only.
     */
    rsv = (ext4_r_blocks_count(sbi->s_es) >> sbi->s_cluster_bits) +
          resv_clusters;

    if (free_clusters - (nclusters + rsv + dirty_clusters) <
                    EXT4_FREECLUSTERS_WATERMARK) {
        free_clusters  = percpu_counter_sum_positive(fcc);
        dirty_clusters = percpu_counter_sum_positive(dcc);
    }
    /* Check whether we have space after accounting for current
     * dirty clusters & root reserved clusters.
     */
    if (free_clusters >= (rsv + nclusters + dirty_clusters))
        return 1;

    /* Hm, nope.  Are (enough) root reserved clusters available? */
    if (uid_eq(sbi->s_resuid, current_fsuid()) ||
        (!gid_eq(sbi->s_resgid, GLOBAL_ROOT_GID) && in_group_p(sbi->s_resgid)) ||
        capable(CAP_SYS_RESOURCE) ||
        (flags & EXT4_MB_USE_ROOT_BLOCKS)) {

        if (free_clusters >= (nclusters + dirty_clusters +
                      resv_clusters))
            return 1;
    }
    /* No free blocks. Let's see if we can dip into reserved pool */
    if (flags & EXT4_MB_USE_RESERVED) {
        if (free_clusters >= (nclusters + dirty_clusters))
            return 1;
    }

    return 0;
}
```