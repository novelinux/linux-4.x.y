struct ext4_map_blocks
========================================

path: fs/ext4/ext4.h
```
struct ext4_map_blocks {
    ext4_fsblk_t m_pblk;
    ext4_lblk_t m_lblk;
    unsigned int m_len;
    unsigned int m_flags;
};
```