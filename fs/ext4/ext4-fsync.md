# Ext4 - fsync

## fsync

```
fsync
 |
sys_fsync
 |
do_fsync
 |
vfs_fsync
 |
vfs_fsync_range
 |
file->f_op->fsync -> ext4_sync_file
```

### ext4_sync_file

```
ext4_sync_file { event: ext4_sync_file_enter }
 |
 +-> filemap_write_and_wait_range
 |   |
 |   __filemap_fdatawrite_range
 |   |
 |   do_writepages
 |   |
 |   mapping->a_ops->writepages
 |   |
 |   ext4_writepages { event: ext4_writepages }
 |
 +-> { event: ext4_sync_file_exit }
```

#### ext4_writepages

```
ext4_writepages { event: ext4_writepages }
 |
 +-> ext4_journal_start_with_reserve
 |   |
 |   __ext4_journal_start
 |   |
 |   __ext4_journal_start_sb { event: ext4_journal_start }
 |   |
 |   +-> jbd2__journal_start { event: jbd2_handle_start }
 |
 +-> { event: ext4_da_write_pages }
 |
 +-> mpage_prepare_extent_to_map
 |
 +-> mpage_map_and_submit_extent
 |   |
 |   +-> mpage_map_one_extent { event: ext4_da_write_pages_extent }
 |   |   |
 |   |   ext4_map_blocks
 |   |   |
 |   |   +-> ext4_es_lookup_extent { event: ext4_es_lookup_extent_enter/exit }
 |   |   |
 |   |   +-> ext4_ext_map_blocks
 |   |                |
 |   |   +-> { event: ext4_ext_map_blocks_enter }
 |   |   |
 |   |   +-> ext4_mb_new_blocks { event: ext4_request_blocks }
 |   |   |   |
 |   |   |   +-> ext4_mb_release_context - ext4_mb_collect_stats { event: ext4_mballoc_prealloc }
 |   |   |   |
 |   |   |   +-> { event: ext4_allocate_blocks }
 |   |   |
 |   |   +-> ext4_ext_insert_extent
 |   |   |   |
 |   |   |   ext4_ext_dirty -> __ext4_ext_dirty
 |   |   |                            |
 |   |   |   ext4_mark_inode_dirty { event: ext4_mark_inode_dirty }
 |   |   |
 |   |   +-> get_reserved_cluster_alloc { event: ext4_get_reserved_cluster_alloc }
 |   |   |
 |   |   +-> ext4_da_update_reserve_space { event: ext4_da_update_reserve_space }
 |   |   |
 |   |   +-> { event: ext4_ext_map_blocks_exit }
 |   |
 |   +-> mpage_map_and_submit_buffers
```