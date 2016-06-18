ext4_file_open
========================================

path: fs/ext4/file.c
```
static int ext4_file_open(struct inode * inode, struct file * filp)
{
    struct super_block *sb = inode->i_sb;
    struct ext4_sb_info *sbi = EXT4_SB(inode->i_sb);
    struct vfsmount *mnt = filp->f_path.mnt;
    struct dentry *dir;
    struct path path;
    char buf[64], *cp;
    int ret;

    if (unlikely(!(sbi->s_mount_flags & EXT4_MF_MNTDIR_SAMPLED) &&
             !(sb->s_flags & MS_RDONLY))) {
        sbi->s_mount_flags |= EXT4_MF_MNTDIR_SAMPLED;
        /*
         * Sample where the filesystem has been mounted and
         * store it in the superblock for sysadmin convenience
         * when trying to sort through large numbers of block
         * devices or filesystem images.
         */
        memset(buf, 0, sizeof(buf));
        path.mnt = mnt;
        path.dentry = mnt->mnt_root;
        cp = d_path(&path, buf, sizeof(buf));
        if (!IS_ERR(cp)) {
            handle_t *handle;
            int err;

            handle = ext4_journal_start_sb(sb, EXT4_HT_MISC, 1);
            if (IS_ERR(handle))
                return PTR_ERR(handle);
            BUFFER_TRACE(sbi->s_sbh, "get_write_access");
            err = ext4_journal_get_write_access(handle, sbi->s_sbh);
            if (err) {
                ext4_journal_stop(handle);
                return err;
            }
            strlcpy(sbi->s_es->s_last_mounted, cp,
                sizeof(sbi->s_es->s_last_mounted));
            ext4_handle_dirty_super(handle, sb);
            ext4_journal_stop(handle);
        }
    }
    if (ext4_encrypted_inode(inode)) {
        ret = ext4_get_encryption_info(inode);
        if (ret)
            return -EACCES;
        if (ext4_encryption_info(inode) == NULL)
            return -ENOKEY;
    }

    dir = dget_parent(file_dentry(filp));
    if (ext4_encrypted_inode(d_inode(dir)) &&
        !ext4_is_child_context_consistent_with_parent(d_inode(dir), inode)) {
        ext4_warning(inode->i_sb,
                 "Inconsistent encryption contexts: %lu/%lu\n",
                 (unsigned long) d_inode(dir)->i_ino,
                 (unsigned long) inode->i_ino);
        dput(dir);
        return -EPERM;
    }
    dput(dir);
    /*
     * Set up the jbd2_inode if we are opening the inode for
     * writing and the journal is present
     */
    if (filp->f_mode & FMODE_WRITE) {
        ret = ext4_inode_attach_jinode(inode);
        if (ret < 0)
            return ret;
    }
    return dquot_file_open(inode, filp);
}
```
