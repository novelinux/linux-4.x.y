# Ext4 JBD2

## open | O_CREATE

```
open
 |
sys_openat
 |
do_sys_open
 |
do_filp_open
 |
path_openat
 |
do_last
 |
lookup_open
 |
 +-> lookup_real
 |
 +-> vfs_create
```

### lookup_real

```
lookup_real
 |
ext4_lookup
 |
ext4_find_entry
 |
ext4_getblk
 |
ext4_map_blocks
 |
ext4_es_lookup_extent { event: ext4_es_lookup_extent_enter/ext4_es_lookup_extent_exit }
```

### vfs_create

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
 |   |   +-> ext4_read_dirblock -> __ext4_read_dirblock
 |   |   |   |
 |   |   |   +-> ext4_bread -> ext4_getblk
 |   |   |                           |
 |   |   |   ext4_map_blocks  <------+
 |   |   |   |
 |   |   |   ext4_es_lookup_extent
 |   |   |   |
 |   |   |   +-> { event: ext4_es_lookup_extent_enter/ext4_es_lookup_extent_exit }
 |   |   |
 |   |   +-> add_dirent_to_buf
 |   |   |
 |   |   +-> ext4_mark_inode_dirty { event: ext4_mark_inode_dirty }
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

### vfs_write

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

### ext4_da_write_begin

```
ext4_da_write_begin { event: ext4_da_write_begin }
 |
 +-> ext4_journal_start -> __ext4_journal_start
 |                                  |
 |   __ext4_journal_start_sb { event: ext4_journal_start }
 |   |
 |   +-> jbd2__journal_start { event: jbd2_handle_start }
 |
 ext4_block_write_begin
 |
 ext4_get_block_write
 |
 ext4_da_map_blocks
 |
 +-> ext4_es_lookup_extent { event: ext4_es_lookup_extent_enter/ext4_es_lookup_extent_exit }
 |
 +-> ext4_ext_map_blocks { event: ext4_ext_map_blocks_enter }
 |   |
 |   +-> ext4_ext_put_gap_in_cache
 |   |   |
     |   +-> ext4_es_find_delayed_extent_range { event: ext4_es_find_delayed_extent_range_enter/exit }
 |   |   |
 |   |   +-> ext4_es_insert_extent { event: ext4_es_insert_extent }
 |   |
 |   +-> { event: ext4_ext_map_blocks_exit }
 |
 +-> ext4_da_reserve_space { event: ext4_da_reserve_space }
 |
 +-> ext4_es_insert_extent { event: ext4_es_insert_extent }
```

### ext4_da_write_end

```
ext4_da_write_end { event: ext4_da_write_end }
 |
```
