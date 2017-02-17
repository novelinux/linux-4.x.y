ext4_ioctl
========================================

path: fs/ext4/ioctl.c
```
long ext4_ioctl(struct file *filp, unsigned int cmd, unsigned long arg)
{
	struct inode *inode = file_inode(filp);
	struct super_block *sb = inode->i_sb;
	struct ext4_inode_info *ei = EXT4_I(inode);
	unsigned int flags;

	ext4_debug("cmd = %u, arg = %lu\n", cmd, arg);

	switch (cmd) {
        ...
```

EXT4_IOC_SET_ENCRYPTION_POLICY
----------------------------------------

```
        case EXT4_IOC_SET_ENCRYPTION_POLICY: {
#ifdef CONFIG_EXT4_FS_ENCRYPTION
		struct ext4_encryption_policy policy;
		int err = 0;

		if (copy_from_user(&policy,
				   (struct ext4_encryption_policy __user *)arg,
				   sizeof(policy))) {
			err = -EFAULT;
			goto encryption_policy_out;
		}

		err = ext4_process_policy(&policy, inode);
encryption_policy_out:
		return err;
#else
		return -EOPNOTSUPP;
#endif
	}
        ...
        }
        ...
}
```

### ext4_process_policy

https://github.com/novelinux/linux-4.x.y/blob/master/fs/ext4/crypto_policy.c/ext4_process_policy.md
