ext4_set_aops
========================================

如果对应的超级块指定了DELALLOC标志则对应的address_space_operations
指针指定为ext4_da_aops，否则指定为ext4_aops.

```
delalloc
      Deferring block allocation until write-out time.

nodelalloc
      Disable delayed allocation. Blocks are allocated when data is copied from user to page cache.
```

* sagit

```
/dev/block/sda17 on /data type ext4 (rw,seclabel,nosuid,nodev,relatime,discard,noauto_da_alloc,data=ordered)
```

path: fs/ext4/inode.c
```
void ext4_set_aops(struct inode *inode)
{
    switch (ext4_inode_journal_mode(inode)) {
    case EXT4_INODE_ORDERED_DATA_MODE:
        ext4_set_inode_state(inode, EXT4_STATE_ORDERED_MODE);
        break;
    case EXT4_INODE_WRITEBACK_DATA_MODE:
        ext4_clear_inode_state(inode, EXT4_STATE_ORDERED_MODE);
        break;
    case EXT4_INODE_JOURNAL_DATA_MODE:
        inode->i_mapping->a_ops = &ext4_journalled_aops;
        return;
    default:
        BUG();
    }
    if (test_opt(inode->i_sb, DELALLOC))
        inode->i_mapping->a_ops = &ext4_da_aops;
    else
        inode->i_mapping->a_ops = &ext4_aops;
}
```



ext4_journalled_aops
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/fs/ext4/inode.c/ext4_journalled_aops.md

ext4_da_aops
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/fs/ext4/inode.c/ext4_da_aops.md

ext4_aops
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/fs/ext4/inode.c/ext4_aops.md
