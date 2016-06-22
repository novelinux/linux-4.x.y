ext4_da_reserve_space
========================================

Arguments
----------------------------------------

path: fs/ext4/inode.c
```
/*
 * Reserve space for a single cluster
 */
static int ext4_da_reserve_space(struct inode *inode)
{
    struct ext4_sb_info *sbi = EXT4_SB(inode->i_sb);
    struct ext4_inode_info *ei = EXT4_I(inode);
    int ret;
```

dquot_reserve_block
----------------------------------------

```
    /*
     * We will charge metadata quota at writeout time; this saves
     * us from metadata over-estimation, though we may go over by
     * a small amount in the end.  Here we just reserve for data.
     */
    ret = dquot_reserve_block(inode, EXT4_C2B(sbi, 1));
    if (ret)
        return ret;
```

ext4_claim_free_clusters
----------------------------------------

```
    spin_lock(&ei->i_block_reservation_lock);
    if (ext4_claim_free_clusters(sbi, 1, 0)) {
        spin_unlock(&ei->i_block_reservation_lock);
        dquot_release_reservation_block(inode, EXT4_C2B(sbi, 1));
        return -ENOSPC;
    }
    ei->i_reserved_data_blocks++;
    trace_ext4_da_reserve_space(inode);
    spin_unlock(&ei->i_block_reservation_lock);

    return 0;       /* success */
}
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/ext4/balloc.c/ext4_claim_free_clusters.md
