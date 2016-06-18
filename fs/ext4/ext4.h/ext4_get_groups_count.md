ext4_get_groups_count
========================================

path: fs/ext4/ext4.h
```
/*
 * Reading s_groups_count requires using smp_rmb() afterwards.  See
 * the locking protocol documented in the comments of ext4_group_add()
 * in resize.c
 */
static inline ext4_group_t ext4_get_groups_count(struct super_block *sb)
{
    ext4_group_t    ngroups = EXT4_SB(sb)->s_groups_count;

    smp_rmb();
    return ngroups;
}
```