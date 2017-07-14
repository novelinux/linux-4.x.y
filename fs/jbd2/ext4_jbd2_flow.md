# Ext4 JBD2

## open | O_CREATE

```
vfs_create
 |
ext4_create
 |
 +-> ext4_new_inode_start_handle
 |   |
 |   __ext4_new_inode
 |   |
 |   +-> { event: ext4_request_inode }
 |   |
 |   +-> __ext4_journal_start_sb { event: ext4_journal_start }
 |   |   |
 |   |   +-> jbd2__journal_start { event: jbd2_handle_start }
 |   |
 |   +-> ext4_ext_tree_init
 |   |   |
 |   |   +-> ext4_mark_inode_dirty { event: ext4_mark_inode_dirty }
 |   |
 |   +-> ext4_mark_inode_dirty { event: ext4_mark_inode_dirty }
 |   |
 |   +-> { event: ext4_allocate_inode }
 |
 +-> ext4_journal_current_handle
 |
 +-> ext4_add_nondir
 |   |
 |   +-> ext4_add_entry
 |   |   |
 |   |   add_dirent_to_buf
 |   |   |
 |   |   + ext4_mark_inode_dirty { event: ext4_mark_inode_dirty }
 |   |
 |   +-> ext4_mark_inode_dirty { event: ext4_mark_inode_dirty }
 |
 +-> ext4_journal_stop
     |
     __ext4_journal_stop
     |
     jbd2_journal_stop { event: jbd2_handle_stats }
```

## write

```
vfs_write
 |
__vfs_write
 |
new_sync_write
 |
ext4_file_write_iter
 |
 +-> __generic_file_write_iter
 |  |
 |  generic_perform_write
 |  |
 |  +-> ext4_da_write_begin
 |  |
 |  +-> ext4_da_write_end
 |
 +-> generic_write_sync
```