struct ext4_inode
========================================

每个块组都包含一个inode位图和一个本地的inode表，in-ode表可能延续到几个块。位图的内容
与本地块组相关，不会复制到文件系统中任何其他位置。inode位图用于概述块组中已用和空闲的inode。
通常，每个inode对应到一个比特位，有“已用”和“空闲”两种状态。inode数据保存在inode表中，
包括了许多顺序存储的inode结构。这些数据如何保存到存储介质，由下列冗长的结构定义：

path: fs/ext4/ext4.h
```
/*
 * Structure of an inode on the disk
 */
struct ext4_inode {
    __le16    i_mode;        /* File mode */
    __le16    i_uid;        /* Low 16 bits of Owner Uid */
    __le32    i_size_lo;    /* Size in bytes */
    __le32    i_atime;    /* Access time */
    __le32    i_ctime;    /* Inode Change time */
    __le32    i_mtime;    /* Modification time */
    __le32    i_dtime;    /* Deletion Time */
    __le16    i_gid;        /* Low 16 bits of Group Id */
    __le16    i_links_count;    /* Links count */
    __le32    i_blocks_lo;    /* Blocks count */
    __le32    i_flags;    /* File flags */
    union {
        struct {
            __le32  l_i_version;
        } linux1;
        struct {
            __u32  h_i_translator;
        } hurd1;
        struct {
            __u32  m_i_reserved1;
        } masix1;
    } osd1;                /* OS dependent 1 */
    __le32    i_block[EXT4_N_BLOCKS];/* Pointers to blocks */
    __le32    i_generation;    /* File version (for NFS) */
    __le32    i_file_acl_lo;    /* File ACL */
    __le32    i_size_high;
    __le32    i_obso_faddr;    /* Obsoleted fragment address */
    union {
        struct {
            __le16    l_i_blocks_high; /* were l_i_reserved1 */
            __le16    l_i_file_acl_high;
            __le16    l_i_uid_high;    /* these 2 fields */
            __le16    l_i_gid_high;    /* were reserved2[0] */
            __le16    l_i_checksum_lo;/* crc32c(uuid+inum+inode) LE */
            __le16    l_i_reserved;
        } linux2;
        struct {
            __le16    h_i_reserved1;    /* Obsoleted fragment number/size which are removed in ext4 */
            __u16    h_i_mode_high;
            __u16    h_i_uid_high;
            __u16    h_i_gid_high;
            __u32    h_i_author;
        } hurd2;
        struct {
            __le16    h_i_reserved1;    /* Obsoleted fragment number/size which are removed in ext4 */
            __le16    m_i_file_acl_high;
            __u32    m_i_reserved2[2];
        } masix2;
    } osd2;                /* OS dependent 2 */
    __le16    i_extra_isize;
    __le16    i_checksum_hi;    /* crc32c(uuid+inum+inode) BE */
    __le32  i_ctime_extra;  /* extra Change time      (nsec << 2 | epoch) */
    __le32  i_mtime_extra;  /* extra Modification time(nsec << 2 | epoch) */
    __le32  i_atime_extra;  /* extra Access time      (nsec << 2 | epoch) */
    __le32  i_crtime;       /* File Creation time */
    __le32  i_crtime_extra; /* extra FileCreationtime (nsec << 2 | epoch) */
    __le32  i_version_hi;    /* high 32 bits for 64-bit version */
};
```
