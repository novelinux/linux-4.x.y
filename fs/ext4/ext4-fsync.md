# Ext4 - fsync

## fsync - test-open-write-fsync

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
file->f_op->fsync -> **ext4_sync_file**
```

### ext4_sync_file

```
ext4_sync_file
 |
 +-> { event: ext4_sync_file_enter }
 |
 +-> filemap_write_and_wait_range
 |   |
 |   __filemap_fdatawrite_range
 |   |
 |   do_writepages
 |   |
 |   mapping->a_ops->writepages
 |   |
 |   **ext4_writepages** { event: ext4_writepages }
 |
 +-> **jbd2/sda16-8-578** (kjournald2)
 |
 +-> { event: ext4_sync_file_exit }
```

#### ext4_writepages

```
ext4_writepages
 |
 +-> { event: ext4_writepages }
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
 |   |   +-> **ext4_map_blocks**
 |   |
 |   +-> mpage_map_and_submit_buffers
 |   |
 |   +-> ext4_mark_inode_dirty { event: ext4_mark_inode_dirty }
 |
 +-> ext4_journal_stop -> __ext4_journal_stop
 |                                |
 |   jbd2_journal_stop { event: jbd2_handle_stats }
 |
 +-> { event: ext4_writepages_result }
```

#### ext4_map_blocks

```
ext4_map_blocks
 |
 +-> ext4_es_lookup_extent { event: ext4_es_lookup_extent_enter/exit }
 |
 +-> ext4_ext_map_blocks
 |   |
 |   +-> { event: ext4_ext_map_blocks_enter }
 |   |
 |   +-> ext4_mb_new_blocks { event: ext4_request_blocks }
 |   |   |
 |   |   +-> ext4_mb_release_context - ext4_mb_collect_stats { event: ext4_mballoc_prealloc }
 |   |   |
 |   |   +-> { event: ext4_allocate_blocks }
 |   |
 |   +-> ext4_ext_insert_extent
 |   |   |
 |   |   +-> ext4_ext_dirty -> __ext4_ext_dirty
 |   |                               |
 |   |   ext4_mark_inode_dirty { event: ext4_mark_inode_dirty }
 |   |
 |   +-> get_reserved_cluster_alloc { event: ext4_get_reserved_cluster_alloc }
 |   |
 |   +-> ext4_da_update_reserve_space { event: ext4_da_update_reserve_space }
 |   |   |
 |   |   +-> dquot_claim_block -> mark_inode_dirty_sync
 |   |                                   |
 |   |      ext4_dirty_inode <- __mark_inode_dirty
 |   |      |
 |   |      +-> ext4_journal_start { event: ext4_journal_start }
 |   |      |
 |   |      +-> ext4_mark_inode_dirty { event: ext4_mark_inode_dirty }
 |   |
 |   +-> { event: ext4_ext_map_blocks_exit }
 |
 +-> ext4_es_insert_extent { event: ext4_es_insert_extent }
```

## kjournald2

```
ext4_fill_super
 |
ext4_load_journal
 |
jbd2_journal_load
 |
 +-> load_superblock
 |
 +-> jbd2_journal_create_slab
 |
 +-> journal_reset
     |
 jbd2_journal_start_thread
 |
 kthread_run( kjournald2 )
 |
 loop: jbd2_journal_commit_transaction
  |
  +-> { event: jbd2_start_commit }
  |
  +-> { event: jbd2_commit_locking }
  |
  +-> { event: jbd2_commit_flushing }
  |
  +-> { event: jbd2_commit_logging }
  |
  +-> journal_submit_commit_record
  |    |
  |   jbd2_journal_get_descriptor_buffer
  |    |
  |   jbd2_journal_next_log_block
  |    |
  |   jbd2_journal_bmap
  |    |
  |   bmap -> inode->i_mapping->a_ops->bmap
  |           |
  |   ext4_bmap
  |    |
  |   generic_block_bmap
  |    |
  |   ext4_get_block -> _ext4_get_block
  |                     |
  |   **ext4_map_blocks** [ loop 7 times ]
  |
  +->  __jbd2_journal_remove_checkpoint { event: jbd2_checkpoint_stats }
  |    |
  |    __jbd2_journal_drop_transaction { event: jbd2_drop_transaction }
  |
  +-> { event: jbd2_run_stats }
  |
  +-> { event: jbd2_end_commit }
```

### ext_map_blocks

```
ext_map_blocks
 |
 +-> ext4_es_lookup_extent { event: ext4_es_lookup_extent_enter/exit }
 |
 +-> ext4_ext_map_blocks
 |   |
 |   +-> { event: ext4_ext_map_blocks_enter }
 |   |
 |   +-> { event: ext4_ext_show_extent }
 |   |
 |   +-> { event: ext4_ext_map_blocks_exit }
 |
 +-> ext4_es_insert_extent { event: ext4_es_insert_extent }
```