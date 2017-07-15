# JBD2

## open-write JBD2 - nobarrier

```
 test-open-writ-4744  [000] ...1   369.187775: ext4_request_inode: dev 259,13 dir 2 mode 0105060
  test-open-writ-4744  [000] ...1   369.187989: ext4_journal_start: dev 259,13 blocks, 35 rsv_blocks, 0 caller __ext4_new_inode+0x750/0x1338
  test-open-writ-4744  [000] ...1   369.188026: jbd2_handle_start: dev 259,13 tid 67 type 4 line_no 2460 requested_blocks 35
  test-open-writ-4744  [000] ...1   369.188193: ext4_mark_inode_dirty: dev 259,13 ino 13 caller ext4_ext_tree_init+0x24/0x30
  test-open-writ-4744  [000] ...1   369.188196: ext4_mark_inode_dirty: dev 259,13 ino 13 caller __ext4_new_inode+0x1108/0x1338
  test-open-writ-4744  [000] ...1   369.188201: ext4_allocate_inode: dev 259,13 ino 13 dir 2 mode 0105060
  test-open-writ-4744  [000] ...1   369.188221: ext4_es_lookup_extent_enter: dev 259,13 ino 2 lblk 0
  test-open-writ-4744  [000] ...1   369.188227: ext4_es_lookup_extent_exit: dev 259,13 ino 2 found 1 [0/1) 1549 W0x10
  test-open-writ-4744  [000] ...1   369.188256: ext4_mark_inode_dirty: dev 259,13 ino 2 caller add_dirent_to_buf+0x170/0x1dc
  test-open-writ-4744  [000] ...1   369.188265: ext4_mark_inode_dirty: dev 259,13 ino 13 caller ext4_add_nondir+0x34/0x7c
  test-open-writ-4744  [000] ...1   369.188286: jbd2_handle_stats: dev 259,13 tid 67 type 4 line_no 2460 interval 0 sync 0 requested_blocks 35 dirtied_blocks 4
  test-open-writ-4744  [000] ...1   369.188365: ext4_da_write_begin: dev 259,13 ino 13 pos 0 len 12 flags 0
  test-open-writ-4744  [000] ...1   369.188391: ext4_journal_start: dev 259,13 blocks, 1 rsv_blocks, 0 caller ext4_da_write_begin+0x1d4/0x304
  test-open-writ-4744  [000] ...1   369.188395: jbd2_handle_start: dev 259,13 tid 67 type 2 line_no 2765 requested_blocks 1
  test-open-writ-4744  [000] ...1   369.188408: ext4_es_lookup_extent_enter: dev 259,13 ino 13 lblk 0
  test-open-writ-4744  [000] ...1   369.188409: ext4_es_lookup_extent_exit: dev 259,13 ino 13 found 0 [0/0) 0
  test-open-writ-4744  [000] ...1   369.188418: ext4_ext_map_blocks_enter: dev 259,13 ino 13 lblk 0 len 1 flags
  test-open-writ-4744  [000] ...1   369.188428: ext4_es_find_delayed_extent_range_enter: dev 259,13 ino 13 lblk 0
  test-open-writ-4744  [000] ...1   369.188435: ext4_es_find_delayed_extent_range_exit: dev 259,13 ino 13 es [0/0) mapped 0 status
  test-open-writ-4744  [000] ...1   369.188442: ext4_es_insert_extent: dev 259,13 ino 13 es [0/4294967295) mapped 576460752303423487 status H
  test-open-writ-4744  [000] ...1   369.188462: ext4_ext_map_blocks_exit: dev 259,13 ino 13 flags  lblk 0 pblk 18446743801386433232 len 1 mflags  ret 0
  test-open-writ-4744  [000] ...2   369.188472: ext4_da_reserve_space: dev 259,13 ino 13 mode 0105060 i_blocks 0 reserved_data_blocks 1 reserved_meta_blocks 0
  test-open-writ-4744  [000] ...1   369.188473: ext4_es_insert_extent: dev 259,13 ino 13 es [0/1) mapped 576460752303423487 status D
  test-open-writ-4744  [000] ...1   369.188503: ext4_da_write_end: dev 259,13 ino 13 pos 0 len 12 copied 12
  test-open-writ-4744  [000] ...1   369.188532: ext4_journal_start: dev 259,13 blocks, 2 rsv_blocks, 0 caller ext4_dirty_inode+0x30/0x68
  test-open-writ-4744  [000] ...1   369.188535: ext4_mark_inode_dirty: dev 259,13 ino 13 caller ext4_dirty_inode+0x44/0x68
  test-open-writ-4744  [000] ...1   369.188538: jbd2_handle_stats: dev 259,13 tid 67 type 2 line_no 2765 interval 0 sync 0 requested_blocks 1 dirtied_blocks 0
   kworker/u16:7-355   [001] ...1   371.965317: ext4_writepages: dev 259,13 ino 13 nr_to_write 13312 pages_skipped 0 range_start 0 range_end 9223372036854775807 sync_mode 0 for_kupdate 1 range_cyclic 1 writeback_index 0
   kworker/u16:7-355   [001] ...1   371.965330: ext4_journal_start: dev 259,13 blocks, 8 rsv_blocks, 0 caller ext4_writepages+0x524/0xd24
   kworker/u16:7-355   [001] ...1   371.965346: jbd2_handle_start: dev 259,13 tid 67 type 2 line_no 2573 requested_blocks 8
   kworker/u16:7-355   [001] ...1   371.965350: ext4_da_write_pages: dev 259,13 ino 13 first_page 0 nr_to_write 13312 sync_mode 0
   kworker/u16:7-355   [001] ...1   371.965373: ext4_da_write_pages_extent: dev 259,13 ino 13 lblk 0 len 1 flags 0x200
   kworker/u16:7-355   [001] ...1   371.965386: ext4_es_lookup_extent_enter: dev 259,13 ino 13 lblk 0
   kworker/u16:7-355   [001] ...1   371.965396: ext4_es_lookup_extent_exit: dev 259,13 ino 13 found 1 [0/1) 576460752303423487 D0x10
   kworker/u16:7-355   [001] ...1   371.965412: ext4_ext_map_blocks_enter: dev 259,13 ino 13 lblk 0 len 1 flags CREATE|DELALLOC|METADATA_NOFAIL
   kworker/u16:7-355   [001] ...1   371.965449: ext4_request_blocks: dev 259,13 ino 13 flags HINT_DATA|DELALLOC_RESV|USE_RESV len 1 lblk 0 goal 0 lleft 0 lright 0 pleft 0 pright 0
   kworker/u16:7-355   [001] ...1   371.965671: ext4_mballoc_alloc: dev 259,13 inode 13 orig 0/0/1@0 goal 0/0/1@0 result 0/1555/1@0 blks 1 grps 1 cr 1 flags HINT_DATA|HINT_NOPREALLOC|DELALLOC_RESV|USE_RESV tail 0 broken 0
   kworker/u16:7-355   [001] ...1   371.965683: ext4_allocate_blocks: dev 259,13 ino 13 flags HINT_DATA|DELALLOC_RESV|USE_RESV len 1 block 1555 lblk 0 goal 0 lleft 0 lright 0 pleft 0 pright 0
   kworker/u16:7-355   [001] ...1   371.965713: ext4_mark_inode_dirty: dev 259,13 ino 13 caller __ext4_ext_dirty+0x6c/0x78
   kworker/u16:7-355   [001] ...1   371.965760: ext4_get_reserved_cluster_alloc: dev 259,13 ino 13 lblk 0 len 1
   kworker/u16:7-355   [001] ...2   371.965770: ext4_da_update_reserve_space: dev 259,13 ino 13 mode 0105060 i_blocks 0 used_blocks 1 reserved_data_blocks 1 reserved_meta_blocks 0 allocated_meta_blocks 0 quota_claim 1
   kworker/u16:7-355   [001] ...1   371.965780: ext4_journal_start: dev 259,13 blocks, 2 rsv_blocks, 0 caller ext4_dirty_inode+0x30/0x68
   kworker/u16:7-355   [001] ...1   371.965786: ext4_mark_inode_dirty: dev 259,13 ino 13 caller ext4_dirty_inode+0x44/0x68
   kworker/u16:7-355   [001] ...1   371.965806: ext4_discard_preallocations: dev 259,13 ino 13
   kworker/u16:7-355   [001] ...1   371.965815: ext4_ext_map_blocks_exit: dev 259,13 ino 13 flags CREATE|DELALLOC|METADATA_NOFAIL lblk 0 pblk 1555 len 1 mflags NM ret 1
   kworker/u16:7-355   [001] ...1   371.965822: ext4_es_insert_extent: dev 259,13 ino 13 es [0/1) mapped 1555 status W
   kworker/u16:7-355   [001] ...1   371.965881: ext4_mark_inode_dirty: dev 259,13 ino 13 caller ext4_writepages+0xc1c/0xd24
   kworker/u16:7-355   [001] ...1   371.965893: jbd2_handle_stats: dev 259,13 tid 67 type 2 line_no 2573 interval 0 sync 0 requested_blocks 8 dirtied_blocks 1
   kworker/u16:7-355   [001] ...1   371.965946: ext4_journal_start: dev 259,13 blocks, 8 rsv_blocks, 0 caller ext4_writepages+0x524/0xd24
   kworker/u16:7-355   [001] ...1   371.965954: jbd2_handle_start: dev 259,13 tid 67 type 2 line_no 2573 requested_blocks 8
   kworker/u16:7-355   [001] ...1   371.965957: ext4_da_write_pages: dev 259,13 ino 13 first_page 1 nr_to_write 13311 sync_mode 0
   kworker/u16:7-355   [001] ...1   371.965963: jbd2_handle_stats: dev 259,13 tid 67 type 2 line_no 2573 interval 0 sync 0 requested_blocks 8 dirtied_blocks 0
   kworker/u16:7-355   [001] ...1   371.965971: ext4_writepages_result: dev 259,13 ino 13 ret 0 pages_written 1 pages_skipped 0 sync_mode 0 writeback_index 1
    jbd2/sda16-8-582   [000] ...1   375.060497: jbd2_start_commit: dev 259,13 transaction 67 sync 0
    jbd2/sda16-8-582   [000] ...2   375.060666: jbd2_commit_locking: dev 259,13 transaction 67 sync 0
    jbd2/sda16-8-582   [000] ...2   375.060711: jbd2_commit_flushing: dev 259,13 transaction 67 sync 0
    jbd2/sda16-8-582   [000] ...1   375.060746: jbd2_commit_logging: dev 259,13 transaction 67 sync 0
    jbd2/sda16-8-582   [000] ...1   375.060779: ext4_es_lookup_extent_enter: dev 259,13 ino 8 lblk 54
    jbd2/sda16-8-582   [000] ...1   375.060795: ext4_es_lookup_extent_exit: dev 259,13 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-582   [000] ...1   375.060812: ext4_ext_map_blocks_enter: dev 259,13 ino 8 lblk 54 len 1 flags
    jbd2/sda16-8-582   [000] ...1   375.060832: ext4_ext_show_extent: dev 259,13 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-582   [000] ...1   375.060845: ext4_ext_map_blocks_exit: dev 259,13 ino 8 flags  lblk 54 pblk 577 len 1 mflags M ret 1
    jbd2/sda16-8-582   [000] ...1   375.060857: ext4_es_insert_extent: dev 259,13 ino 8 es [54/1) mapped 577 status W
    jbd2/sda16-8-582   [000] ...1   375.061054: ext4_es_lookup_extent_enter: dev 259,13 ino 8 lblk 55
    jbd2/sda16-8-582   [000] ...1   375.061059: ext4_es_lookup_extent_exit: dev 259,13 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-582   [000] ...1   375.061063: ext4_ext_map_blocks_enter: dev 259,13 ino 8 lblk 55 len 1 flags
    jbd2/sda16-8-582   [000] ...1   375.061069: ext4_ext_show_extent: dev 259,13 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-582   [000] ...1   375.061073: ext4_ext_map_blocks_exit: dev 259,13 ino 8 flags  lblk 55 pblk 578 len 1 mflags M ret 1
    jbd2/sda16-8-582   [000] ...1   375.061078: ext4_es_insert_extent: dev 259,13 ino 8 es [55/1) mapped 578 status W
    jbd2/sda16-8-582   [000] ...1   375.061117: ext4_es_lookup_extent_enter: dev 259,13 ino 8 lblk 56
    jbd2/sda16-8-582   [000] ...1   375.061122: ext4_es_lookup_extent_exit: dev 259,13 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-582   [000] ...1   375.061126: ext4_ext_map_blocks_enter: dev 259,13 ino 8 lblk 56 len 1 flags
    jbd2/sda16-8-582   [000] ...1   375.061131: ext4_ext_show_extent: dev 259,13 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-582   [000] ...1   375.061135: ext4_ext_map_blocks_exit: dev 259,13 ino 8 flags  lblk 56 pblk 579 len 1 mflags M ret 1
    jbd2/sda16-8-582   [000] ...1   375.061140: ext4_es_insert_extent: dev 259,13 ino 8 es [56/1) mapped 579 status W
    jbd2/sda16-8-582   [000] ...1   375.061159: ext4_es_lookup_extent_enter: dev 259,13 ino 8 lblk 57
    jbd2/sda16-8-582   [000] ...1   375.061163: ext4_es_lookup_extent_exit: dev 259,13 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-582   [000] ...1   375.061167: ext4_ext_map_blocks_enter: dev 259,13 ino 8 lblk 57 len 1 flags
    jbd2/sda16-8-582   [000] ...1   375.061172: ext4_ext_show_extent: dev 259,13 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-582   [000] ...1   375.061176: ext4_ext_map_blocks_exit: dev 259,13 ino 8 flags  lblk 57 pblk 580 len 1 mflags M ret 1
    jbd2/sda16-8-582   [000] ...1   375.061180: ext4_es_insert_extent: dev 259,13 ino 8 es [57/1) mapped 580 status W
    jbd2/sda16-8-582   [000] ...1   375.061198: ext4_es_lookup_extent_enter: dev 259,13 ino 8 lblk 58
    jbd2/sda16-8-582   [000] ...1   375.061202: ext4_es_lookup_extent_exit: dev 259,13 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-582   [000] ...1   375.061207: ext4_ext_map_blocks_enter: dev 259,13 ino 8 lblk 58 len 1 flags
    jbd2/sda16-8-582   [000] ...1   375.061211: ext4_ext_show_extent: dev 259,13 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-582   [000] ...1   375.061216: ext4_ext_map_blocks_exit: dev 259,13 ino 8 flags  lblk 58 pblk 581 len 1 mflags M ret 1
    jbd2/sda16-8-582   [000] ...1   375.061220: ext4_es_insert_extent: dev 259,13 ino 8 es [58/1) mapped 581 status W
    jbd2/sda16-8-582   [000] ...1   375.061238: ext4_es_lookup_extent_enter: dev 259,13 ino 8 lblk 59
    jbd2/sda16-8-582   [000] ...1   375.061242: ext4_es_lookup_extent_exit: dev 259,13 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-582   [000] ...1   375.061246: ext4_ext_map_blocks_enter: dev 259,13 ino 8 lblk 59 len 1 flags
    jbd2/sda16-8-582   [000] ...1   375.061251: ext4_ext_show_extent: dev 259,13 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-582   [000] ...1   375.061254: ext4_ext_map_blocks_exit: dev 259,13 ino 8 flags  lblk 59 pblk 582 len 1 mflags M ret 1
    jbd2/sda16-8-582   [000] ...1   375.061259: ext4_es_insert_extent: dev 259,13 ino 8 es [59/1) mapped 582 status W
    jbd2/sda16-8-582   [000] ...1   375.073079: ext4_es_lookup_extent_enter: dev 259,13 ino 8 lblk 60
    jbd2/sda16-8-582   [000] ...1   375.073165: ext4_es_lookup_extent_exit: dev 259,13 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-582   [000] ...1   375.073173: ext4_ext_map_blocks_enter: dev 259,13 ino 8 lblk 60 len 1 flags
    jbd2/sda16-8-582   [000] ...1   375.073181: ext4_ext_show_extent: dev 259,13 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-582   [000] ...1   375.073188: ext4_ext_map_blocks_exit: dev 259,13 ino 8 flags  lblk 60 pblk 583 len 1 mflags M ret 1
    jbd2/sda16-8-582   [000] ...1   375.073196: ext4_es_insert_extent: dev 259,13 ino 8 es [60/1) mapped 583 status W
    jbd2/sda16-8-582   [000] ...2   375.074594: jbd2_run_stats: dev 259,13 tid 67 wait 0 request_delay 0 running 5880 locked 0 flushing 0 logging 10 handle_count 4 blocks 5 blocks_logged 6
    jbd2/sda16-8-582   [000] ...1   375.074686: jbd2_end_commit: dev 259,13 transaction 67 sync 0 head 60
```

## open-write-O_SYNC - nobarrier

```
  test-open-writ-4922  [000] ...1  1425.147209: ext4_request_inode: dev 259,13 dir 2 mode 0100000
  test-open-writ-4922  [000] ...1  1425.147433: ext4_journal_start: dev 259,13 blocks, 35 rsv_blocks, 0 caller __ext4_new_inode+0x750/0x1338
  test-open-writ-4922  [000] ...1  1425.147470: jbd2_handle_start: dev 259,13 tid 68 type 4 line_no 2460 requested_blocks 35
  test-open-writ-4922  [000] ...1  1425.147634: ext4_mark_inode_dirty: dev 259,13 ino 14 caller ext4_ext_tree_init+0x24/0x30
  test-open-writ-4922  [000] ...1  1425.147638: ext4_mark_inode_dirty: dev 259,13 ino 14 caller __ext4_new_inode+0x1108/0x1338
  test-open-writ-4922  [000] ...1  1425.147644: ext4_allocate_inode: dev 259,13 ino 14 dir 2 mode 0100000
  test-open-writ-4922  [000] ...1  1425.147662: ext4_es_lookup_extent_enter: dev 259,13 ino 2 lblk 0
  test-open-writ-4922  [000] ...1  1425.147670: ext4_es_lookup_extent_exit: dev 259,13 ino 2 found 1 [0/1) 1549 W0x10
  test-open-writ-4922  [000] ...1  1425.147699: ext4_mark_inode_dirty: dev 259,13 ino 2 caller add_dirent_to_buf+0x170/0x1dc
  test-open-writ-4922  [000] ...1  1425.147709: ext4_mark_inode_dirty: dev 259,13 ino 14 caller ext4_add_nondir+0x34/0x7c
  test-open-writ-4922  [000] ...1  1425.147730: jbd2_handle_stats: dev 259,13 tid 68 type 4 line_no 2460 interval 0 sync 0 requested_blocks 35 dirtied_blocks 4
  test-open-writ-4922  [000] ...1  1425.147815: ext4_da_write_begin: dev 259,13 ino 14 pos 0 len 12 flags 0
  test-open-writ-4922  [000] ...1  1425.147838: ext4_journal_start: dev 259,13 blocks, 1 rsv_blocks, 0 caller ext4_da_write_begin+0x1d4/0x304
  test-open-writ-4922  [000] ...1  1425.147840: jbd2_handle_start: dev 259,13 tid 68 type 2 line_no 2765 requested_blocks 1
  test-open-writ-4922  [000] ...1  1425.147854: ext4_es_lookup_extent_enter: dev 259,13 ino 14 lblk 0
  test-open-writ-4922  [000] ...1  1425.147854: ext4_es_lookup_extent_exit: dev 259,13 ino 14 found 0 [0/0) 0
  test-open-writ-4922  [000] ...1  1425.147862: ext4_ext_map_blocks_enter: dev 259,13 ino 14 lblk 0 len 1 flags
  test-open-writ-4922  [000] ...1  1425.147874: ext4_es_find_delayed_extent_range_enter: dev 259,13 ino 14 lblk 0
  test-open-writ-4922  [000] ...1  1425.147881: ext4_es_find_delayed_extent_range_exit: dev 259,13 ino 14 es [0/0) mapped 0 status
  test-open-writ-4922  [000] ...1  1425.147887: ext4_es_insert_extent: dev 259,13 ino 14 es [0/4294967295) mapped 576460752303423487 status H
  test-open-writ-4922  [000] ...1  1425.147909: ext4_ext_map_blocks_exit: dev 259,13 ino 14 flags  lblk 0 pblk 18446743800474598096 len 1 mflags  ret 0
  test-open-writ-4922  [000] ...2  1425.147919: ext4_da_reserve_space: dev 259,13 ino 14 mode 0100000 i_blocks 0 reserved_data_blocks 1 reserved_meta_blocks 0
  test-open-writ-4922  [000] ...1  1425.147922: ext4_es_insert_extent: dev 259,13 ino 14 es [0/1) mapped 576460752303423487 status D
  test-open-writ-4922  [000] ...1  1425.147951: ext4_da_write_end: dev 259,13 ino 14 pos 0 len 12 copied 12
  test-open-writ-4922  [000] ...1  1425.147981: ext4_journal_start: dev 259,13 blocks, 2 rsv_blocks, 0 caller ext4_dirty_inode+0x30/0x68
  test-open-writ-4922  [000] ...1  1425.147982: ext4_mark_inode_dirty: dev 259,13 ino 14 caller ext4_dirty_inode+0x44/0x68
  test-open-writ-4922  [000] ...1  1425.147984: jbd2_handle_stats: dev 259,13 tid 68 type 2 line_no 2765 interval 0 sync 0 requested_blocks 1 dirtied_blocks 0
  test-open-writ-4922  [000] ...1  1425.148001: ext4_sync_file_enter: dev 259,13 ino 14 parent 2 datasync 0
  test-open-writ-4922  [000] ...1  1425.148010: ext4_writepages: dev 259,13 ino 14 nr_to_write 9223372036854775807 pages_skipped 0 range_start 0 range_end 11 sync_mode 1 for_kupdate 0 range_cyclic 0 writeback_index 0
  test-open-writ-4922  [000] ...1  1425.148029: ext4_journal_start: dev 259,13 blocks, 8 rsv_blocks, 0 caller ext4_writepages+0x524/0xd24
  test-open-writ-4922  [000] ...1  1425.148031: jbd2_handle_start: dev 259,13 tid 68 type 2 line_no 2573 requested_blocks 8
  test-open-writ-4922  [000] ...1  1425.148036: ext4_da_write_pages: dev 259,13 ino 14 first_page 0 nr_to_write 9223372036854775807 sync_mode 1
  test-open-writ-4922  [000] ...1  1425.148055: ext4_da_write_pages_extent: dev 259,13 ino 14 lblk 0 len 1 flags 0x200
  test-open-writ-4922  [000] ...1  1425.148056: ext4_es_lookup_extent_enter: dev 259,13 ino 14 lblk 0
  test-open-writ-4922  [000] ...1  1425.148056: ext4_es_lookup_extent_exit: dev 259,13 ino 14 found 1 [0/1) 576460752303423487 D0x10
  test-open-writ-4922  [000] ...1  1425.148058: ext4_ext_map_blocks_enter: dev 259,13 ino 14 lblk 0 len 1 flags CREATE|DELALLOC|METADATA_NOFAIL
  test-open-writ-4922  [000] ...1  1425.148076: ext4_request_blocks: dev 259,13 ino 14 flags HINT_DATA|DELALLOC_RESV|USE_RESV len 1 lblk 0 goal 0 lleft 0 lright 0 pleft 0 pright 0
  test-open-writ-4922  [000] ...1  1425.148135: ext4_mb_new_group_pa: dev 259,13 ino 14 pstart 2560 len 512 lstart 2560
  test-open-writ-4922  [000] ...1  1425.148170: ext4_mballoc_alloc: dev 259,13 inode 14 orig 0/0/1@0 goal 0/0/512@0 result 0/2560/512@0 blks 1 grps 1 cr 0 flags HINT_DATA|HINT_GRP_ALLOC|DELALLOC_RESV|USE_RESV tail 0 broken 0
  test-open-writ-4922  [000] ...1  1425.148176: ext4_allocate_blocks: dev 259,13 ino 14 flags HINT_DATA|DELALLOC_RESV|USE_RESV len 1 block 2560 lblk 0 goal 0 lleft 0 lright 0 pleft 0 pright 0
  test-open-writ-4922  [000] ...1  1425.148192: ext4_mark_inode_dirty: dev 259,13 ino 14 caller __ext4_ext_dirty+0x6c/0x78
  test-open-writ-4922  [000] ...1  1425.148205: ext4_get_reserved_cluster_alloc: dev 259,13 ino 14 lblk 0 len 1
  test-open-writ-4922  [000] ...2  1425.148210: ext4_da_update_reserve_space: dev 259,13 ino 14 mode 0100000 i_blocks 0 used_blocks 1 reserved_data_blocks 1 reserved_meta_blocks 0 allocated_meta_blocks 0 quota_claim 1
  test-open-writ-4922  [000] ...1  1425.148216: ext4_journal_start: dev 259,13 blocks, 2 rsv_blocks, 0 caller ext4_dirty_inode+0x30/0x68
  test-open-writ-4922  [000] ...1  1425.148216: ext4_mark_inode_dirty: dev 259,13 ino 14 caller ext4_dirty_inode+0x44/0x68
  test-open-writ-4922  [000] ...1  1425.148219: ext4_ext_map_blocks_exit: dev 259,13 ino 14 flags CREATE|DELALLOC|METADATA_NOFAIL lblk 0 pblk 2560 len 1 mflags NM ret 1
  test-open-writ-4922  [000] ...1  1425.148222: ext4_es_insert_extent: dev 259,13 ino 14 es [0/1) mapped 2560 status W
  test-open-writ-4922  [000] ...1  1425.148271: ext4_mark_inode_dirty: dev 259,13 ino 14 caller ext4_writepages+0xc1c/0xd24
  test-open-writ-4922  [000] ...1  1425.148274: jbd2_handle_stats: dev 259,13 tid 68 type 2 line_no 2573 interval 0 sync 0 requested_blocks 8 dirtied_blocks 1
  test-open-writ-4922  [000] .n.1  1425.148651: ext4_writepages_result: dev 259,13 ino 14 ret 0 pages_written 1 pages_skipped 0 sync_mode 1 writeback_index 0
    jbd2/sda16-8-582   [001] ...1  1425.156069: jbd2_start_commit: dev 259,13 transaction 68 sync 0
    jbd2/sda16-8-582   [001] ...2  1425.156093: jbd2_commit_locking: dev 259,13 transaction 68 sync 0
    jbd2/sda16-8-582   [001] ...3  1425.156101: jbd2_checkpoint_stats: dev 259,13 tid 66 chp_time 0 forced_to_close 0 written 0 dropped 5
    jbd2/sda16-8-582   [001] ...3  1425.156107: jbd2_drop_transaction: dev 259,13 transaction 66 sync 0
    jbd2/sda16-8-582   [001] ...2  1425.156116: jbd2_commit_flushing: dev 259,13 transaction 68 sync 0
    jbd2/sda16-8-582   [001] ...1  1425.156121: jbd2_commit_logging: dev 259,13 transaction 68 sync 0
    jbd2/sda16-8-582   [001] ...1  1425.156128: ext4_es_lookup_extent_enter: dev 259,13 ino 8 lblk 61
    jbd2/sda16-8-582   [001] ...1  1425.156131: ext4_es_lookup_extent_exit: dev 259,13 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-582   [001] ...1  1425.156135: ext4_ext_map_blocks_enter: dev 259,13 ino 8 lblk 61 len 1 flags
    jbd2/sda16-8-582   [001] ...1  1425.156138: ext4_ext_show_extent: dev 259,13 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-582   [001] ...1  1425.156140: ext4_ext_map_blocks_exit: dev 259,13 ino 8 flags  lblk 61 pblk 584 len 1 mflags M ret 1
    jbd2/sda16-8-582   [001] ...1  1425.156141: ext4_es_insert_extent: dev 259,13 ino 8 es [61/1) mapped 584 status W
    jbd2/sda16-8-582   [001] ...1  1425.156170: ext4_es_lookup_extent_enter: dev 259,13 ino 8 lblk 62
    jbd2/sda16-8-582   [001] ...1  1425.156171: ext4_es_lookup_extent_exit: dev 259,13 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-582   [001] ...1  1425.156172: ext4_ext_map_blocks_enter: dev 259,13 ino 8 lblk 62 len 1 flags
    jbd2/sda16-8-582   [001] ...1  1425.156174: ext4_ext_show_extent: dev 259,13 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-582   [001] ...1  1425.156175: ext4_ext_map_blocks_exit: dev 259,13 ino 8 flags  lblk 62 pblk 585 len 1 mflags M ret 1
    jbd2/sda16-8-582   [001] ...1  1425.156175: ext4_es_insert_extent: dev 259,13 ino 8 es [62/1) mapped 585 status W
    jbd2/sda16-8-582   [001] ...1  1425.156184: ext4_es_lookup_extent_enter: dev 259,13 ino 8 lblk 63
    jbd2/sda16-8-582   [001] ...1  1425.156184: ext4_es_lookup_extent_exit: dev 259,13 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-582   [001] ...1  1425.156185: ext4_ext_map_blocks_enter: dev 259,13 ino 8 lblk 63 len 1 flags
    jbd2/sda16-8-582   [001] ...1  1425.156186: ext4_ext_show_extent: dev 259,13 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-582   [001] ...1  1425.156187: ext4_ext_map_blocks_exit: dev 259,13 ino 8 flags  lblk 63 pblk 586 len 1 mflags M ret 1
    jbd2/sda16-8-582   [001] ...1  1425.156189: ext4_es_insert_extent: dev 259,13 ino 8 es [63/1) mapped 586 status W
    jbd2/sda16-8-582   [001] ...1  1425.156192: ext4_es_lookup_extent_enter: dev 259,13 ino 8 lblk 64
    jbd2/sda16-8-582   [001] ...1  1425.156193: ext4_es_lookup_extent_exit: dev 259,13 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-582   [001] ...1  1425.156194: ext4_ext_map_blocks_enter: dev 259,13 ino 8 lblk 64 len 1 flags
    jbd2/sda16-8-582   [001] ...1  1425.156195: ext4_ext_show_extent: dev 259,13 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-582   [001] ...1  1425.156195: ext4_ext_map_blocks_exit: dev 259,13 ino 8 flags  lblk 64 pblk 587 len 1 mflags M ret 1
    jbd2/sda16-8-582   [001] ...1  1425.156196: ext4_es_insert_extent: dev 259,13 ino 8 es [64/1) mapped 587 status W
    jbd2/sda16-8-582   [001] ...1  1425.156199: ext4_es_lookup_extent_enter: dev 259,13 ino 8 lblk 65
    jbd2/sda16-8-582   [001] ...1  1425.156200: ext4_es_lookup_extent_exit: dev 259,13 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-582   [001] ...1  1425.156201: ext4_ext_map_blocks_enter: dev 259,13 ino 8 lblk 65 len 1 flags
    jbd2/sda16-8-582   [001] ...1  1425.156201: ext4_ext_show_extent: dev 259,13 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-582   [001] ...1  1425.156202: ext4_ext_map_blocks_exit: dev 259,13 ino 8 flags  lblk 65 pblk 588 len 1 mflags M ret 1
    jbd2/sda16-8-582   [001] ...1  1425.156203: ext4_es_insert_extent: dev 259,13 ino 8 es [65/1) mapped 588 status W
    jbd2/sda16-8-582   [001] ...1  1425.156206: ext4_es_lookup_extent_enter: dev 259,13 ino 8 lblk 66
    jbd2/sda16-8-582   [001] ...1  1425.156207: ext4_es_lookup_extent_exit: dev 259,13 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-582   [001] ...1  1425.156207: ext4_ext_map_blocks_enter: dev 259,13 ino 8 lblk 66 len 1 flags
    jbd2/sda16-8-582   [001] ...1  1425.156208: ext4_ext_show_extent: dev 259,13 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-582   [001] ...1  1425.156209: ext4_ext_map_blocks_exit: dev 259,13 ino 8 flags  lblk 66 pblk 589 len 1 mflags M ret 1
    jbd2/sda16-8-582   [001] ...1  1425.156209: ext4_es_insert_extent: dev 259,13 ino 8 es [66/1) mapped 589 status W
    jbd2/sda16-8-582   [001] ...1  1425.156495: ext4_es_lookup_extent_enter: dev 259,13 ino 8 lblk 67
    jbd2/sda16-8-582   [001] ...1  1425.156497: ext4_es_lookup_extent_exit: dev 259,13 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-582   [001] ...1  1425.156498: ext4_ext_map_blocks_enter: dev 259,13 ino 8 lblk 67 len 1 flags
    jbd2/sda16-8-582   [001] ...1  1425.156500: ext4_ext_show_extent: dev 259,13 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-582   [001] ...1  1425.156501: ext4_ext_map_blocks_exit: dev 259,13 ino 8 flags  lblk 67 pblk 590 len 1 mflags M ret 1
    jbd2/sda16-8-582   [001] ...1  1425.156502: ext4_es_insert_extent: dev 259,13 ino 8 es [67/1) mapped 590 status W
    jbd2/sda16-8-582   [001] ...3  1425.157280: jbd2_checkpoint_stats: dev 259,13 tid 67 chp_time 0 forced_to_close 0 written 0 dropped 5
    jbd2/sda16-8-582   [001] ...3  1425.157297: jbd2_drop_transaction: dev 259,13 transaction 67 sync 0
    jbd2/sda16-8-582   [001] ...2  1425.157304: jbd2_run_stats: dev 259,13 tid 68 wait 0 request_delay 0 running 10 locked 0 flushing 0 logging 0 handle_count 3 blocks 5 blocks_logged 6
    jbd2/sda16-8-582   [001] ...1  1425.157307: jbd2_end_commit: dev 259,13 transaction 68 sync 0 head 60
  test-open-writ-4922  [000] ...1  1425.157331: ext4_sync_file_exit: dev 259,13 ino 14 ret 0
  test-open-writ-4922  [000] ...1  1425.157692: ext4_discard_preallocations: dev 259,13 ino 14
   kworker/u16:4-352   [003] ...1  1427.254685: ext4_writepages: dev 259,13 ino 14 nr_to_write 13312 pages_skipped 0 range_start 0 range_end 9223372036854775807 sync_mode 0 for_kupdate 1 range_cyclic 1 writeback_index 0
   kworker/u16:4-352   [003] ...1  1427.254866: ext4_writepages_result: dev 259,13 ino 14 ret 0 pages_written 0 pages_skipped 0 sync_mode 0 writeback_index 0

```

## open-write-fsync - nobarrier

```
  test-open-writ-4930  [001] ...1  1495.732428: ext4_request_inode: dev 259,13 dir 2 mode 0105120
  test-open-writ-4930  [001] ...1  1495.732608: ext4_journal_start: dev 259,13 blocks, 35 rsv_blocks, 0 caller __ext4_new_inode+0x750/0x1338
  test-open-writ-4930  [001] ...1  1495.732644: jbd2_handle_start: dev 259,13 tid 69 type 4 line_no 2460 requested_blocks 35
  test-open-writ-4930  [001] ...1  1495.732810: ext4_mark_inode_dirty: dev 259,13 ino 16 caller ext4_ext_tree_init+0x24/0x30
  test-open-writ-4930  [001] ...1  1495.732815: ext4_mark_inode_dirty: dev 259,13 ino 16 caller __ext4_new_inode+0x1108/0x1338
  test-open-writ-4930  [001] ...1  1495.732821: ext4_allocate_inode: dev 259,13 ino 16 dir 2 mode 0105120
  test-open-writ-4930  [001] ...1  1495.732842: ext4_es_lookup_extent_enter: dev 259,13 ino 2 lblk 0
  test-open-writ-4930  [001] ...1  1495.732849: ext4_es_lookup_extent_exit: dev 259,13 ino 2 found 1 [0/1) 1549 W0x10
  test-open-writ-4930  [001] ...1  1495.732881: ext4_mark_inode_dirty: dev 259,13 ino 2 caller add_dirent_to_buf+0x170/0x1dc
  test-open-writ-4930  [001] ...1  1495.732890: ext4_mark_inode_dirty: dev 259,13 ino 16 caller ext4_add_nondir+0x34/0x7c
  test-open-writ-4930  [001] ...1  1495.732915: jbd2_handle_stats: dev 259,13 tid 69 type 4 line_no 2460 interval 0 sync 0 requested_blocks 35 dirtied_blocks 4
  test-open-writ-4930  [001] ...1  1495.733006: ext4_da_write_begin: dev 259,13 ino 16 pos 0 len 12 flags 0
  test-open-writ-4930  [001] ...1  1495.733036: ext4_journal_start: dev 259,13 blocks, 1 rsv_blocks, 0 caller ext4_da_write_begin+0x1d4/0x304
  test-open-writ-4930  [001] ...1  1495.733038: jbd2_handle_start: dev 259,13 tid 69 type 2 line_no 2765 requested_blocks 1
  test-open-writ-4930  [001] ...1  1495.733053: ext4_es_lookup_extent_enter: dev 259,13 ino 16 lblk 0
  test-open-writ-4930  [001] ...1  1495.733054: ext4_es_lookup_extent_exit: dev 259,13 ino 16 found 0 [0/0) 0
  test-open-writ-4930  [001] ...1  1495.733063: ext4_ext_map_blocks_enter: dev 259,13 ino 16 lblk 0 len 1 flags
  test-open-writ-4930  [001] ...1  1495.733076: ext4_es_find_delayed_extent_range_enter: dev 259,13 ino 16 lblk 0
  test-open-writ-4930  [001] ...1  1495.733083: ext4_es_find_delayed_extent_range_exit: dev 259,13 ino 16 es [0/0) mapped 0 status
  test-open-writ-4930  [001] ...1  1495.733090: ext4_es_insert_extent: dev 259,13 ino 16 es [0/4294967295) mapped 576460752303423487 status H
  test-open-writ-4930  [001] ...1  1495.733109: ext4_ext_map_blocks_exit: dev 259,13 ino 16 flags  lblk 0 pblk 18446743805028793040 len 1 mflags  ret 0
  test-open-writ-4930  [001] ...2  1495.733121: ext4_da_reserve_space: dev 259,13 ino 16 mode 0105120 i_blocks 0 reserved_data_blocks 1 reserved_meta_blocks 0
  test-open-writ-4930  [001] ...1  1495.733123: ext4_es_insert_extent: dev 259,13 ino 16 es [0/1) mapped 576460752303423487 status D
  test-open-writ-4930  [001] ...1  1495.733148: ext4_da_write_end: dev 259,13 ino 16 pos 0 len 12 copied 12
  test-open-writ-4930  [001] ...1  1495.733183: ext4_journal_start: dev 259,13 blocks, 2 rsv_blocks, 0 caller ext4_dirty_inode+0x30/0x68
  test-open-writ-4930  [001] ...1  1495.733186: ext4_mark_inode_dirty: dev 259,13 ino 16 caller ext4_dirty_inode+0x44/0x68
  test-open-writ-4930  [001] ...1  1495.733190: jbd2_handle_stats: dev 259,13 tid 69 type 2 line_no 2765 interval 0 sync 0 requested_blocks 1 dirtied_blocks 0
  test-open-writ-4930  [001] ...1  1495.733213: ext4_sync_file_enter: dev 259,13 ino 16 parent 2 datasync 0
  test-open-writ-4930  [001] ...1  1495.733222: ext4_writepages: dev 259,13 ino 16 nr_to_write 9223372036854775807 pages_skipped 0 range_start 0 range_end 9223372036854775807 sync_mode 1 for_kupdate 0 range_cyclic 0 writeback_index 0
  test-open-writ-4930  [001] ...1  1495.733240: ext4_journal_start: dev 259,13 blocks, 8 rsv_blocks, 0 caller ext4_writepages+0x524/0xd24
  test-open-writ-4930  [001] ...1  1495.733242: jbd2_handle_start: dev 259,13 tid 69 type 2 line_no 2573 requested_blocks 8
  test-open-writ-4930  [001] ...1  1495.733248: ext4_da_write_pages: dev 259,13 ino 16 first_page 0 nr_to_write 9223372036854775807 sync_mode 1
  test-open-writ-4930  [001] ...1  1495.733267: ext4_da_write_pages_extent: dev 259,13 ino 16 lblk 0 len 1 flags 0x200
  test-open-writ-4930  [001] ...1  1495.733269: ext4_es_lookup_extent_enter: dev 259,13 ino 16 lblk 0
  test-open-writ-4930  [001] ...1  1495.733271: ext4_es_lookup_extent_exit: dev 259,13 ino 16 found 1 [0/1) 576460752303423487 D0x10
  test-open-writ-4930  [001] ...1  1495.733274: ext4_ext_map_blocks_enter: dev 259,13 ino 16 lblk 0 len 1 flags CREATE|DELALLOC|METADATA_NOFAIL
  test-open-writ-4930  [001] ...1  1495.733294: ext4_request_blocks: dev 259,13 ino 16 flags HINT_DATA|DELALLOC_RESV|USE_RESV len 1 lblk 0 goal 0 lleft 0 lright 0 pleft 0 pright 0
  test-open-writ-4930  [001] ...1  1495.733356: ext4_mb_new_group_pa: dev 259,13 ino 16 pstart 3072 len 512 lstart 3072
  test-open-writ-4930  [001] ...1  1495.733397: ext4_mballoc_alloc: dev 259,13 inode 16 orig 0/0/1@0 goal 0/0/512@0 result 0/3072/512@0 blks 1 grps 1 cr 0 flags HINT_DATA|HINT_GRP_ALLOC|DELALLOC_RESV|USE_RESV tail 512 broken 1024
  test-open-writ-4930  [001] ...1  1495.733404: ext4_allocate_blocks: dev 259,13 ino 16 flags HINT_DATA|DELALLOC_RESV|USE_RESV len 1 block 3072 lblk 0 goal 0 lleft 0 lright 0 pleft 0 pright 0
  test-open-writ-4930  [001] ...1  1495.733421: ext4_mark_inode_dirty: dev 259,13 ino 16 caller __ext4_ext_dirty+0x6c/0x78
  test-open-writ-4930  [001] ...1  1495.733433: ext4_get_reserved_cluster_alloc: dev 259,13 ino 16 lblk 0 len 1
  test-open-writ-4930  [001] ...2  1495.733440: ext4_da_update_reserve_space: dev 259,13 ino 16 mode 0105120 i_blocks 0 used_blocks 1 reserved_data_blocks 1 reserved_meta_blocks 0 allocated_meta_blocks 0 quota_claim 1
  test-open-writ-4930  [001] ...1  1495.733445: ext4_journal_start: dev 259,13 blocks, 2 rsv_blocks, 0 caller ext4_dirty_inode+0x30/0x68
  test-open-writ-4930  [001] ...1  1495.733446: ext4_mark_inode_dirty: dev 259,13 ino 16 caller ext4_dirty_inode+0x44/0x68
  test-open-writ-4930  [001] ...1  1495.733450: ext4_ext_map_blocks_exit: dev 259,13 ino 16 flags CREATE|DELALLOC|METADATA_NOFAIL lblk 0 pblk 3072 len 1 mflags NM ret 1
  test-open-writ-4930  [001] ...1  1495.733454: ext4_es_insert_extent: dev 259,13 ino 16 es [0/1) mapped 3072 status W
  test-open-writ-4930  [001] ...1  1495.733508: ext4_mark_inode_dirty: dev 259,13 ino 16 caller ext4_writepages+0xc1c/0xd24
  test-open-writ-4930  [001] ...1  1495.733512: jbd2_handle_stats: dev 259,13 tid 69 type 2 line_no 2573 interval 0 sync 0 requested_blocks 8 dirtied_blocks 1
  test-open-writ-4930  [001] ...1  1495.733603: ext4_journal_start: dev 259,13 blocks, 8 rsv_blocks, 0 caller ext4_writepages+0x524/0xd24
  test-open-writ-4930  [001] ...1  1495.733606: jbd2_handle_start: dev 259,13 tid 69 type 2 line_no 2573 requested_blocks 8
  test-open-writ-4930  [001] ...1  1495.733607: ext4_da_write_pages: dev 259,13 ino 16 first_page 1 nr_to_write 9223372036854775806 sync_mode 1
  test-open-writ-4930  [001] ...1  1495.733614: jbd2_handle_stats: dev 259,13 tid 69 type 2 line_no 2573 interval 0 sync 0 requested_blocks 8 dirtied_blocks 0
  test-open-writ-4930  [001] .n.1  1495.733841: ext4_writepages_result: dev 259,13 ino 16 ret 0 pages_written 1 pages_skipped 0 sync_mode 1 writeback_index 1
    jbd2/sda16-8-582   [000] ...1  1495.743853: jbd2_start_commit: dev 259,13 transaction 69 sync 0
    jbd2/sda16-8-582   [000] ...2  1495.743890: jbd2_commit_locking: dev 259,13 transaction 69 sync 0
    jbd2/sda16-8-582   [000] ...2  1495.743904: jbd2_commit_flushing: dev 259,13 transaction 69 sync 0
    jbd2/sda16-8-582   [000] ...1  1495.743918: jbd2_commit_logging: dev 259,13 transaction 69 sync 0
    jbd2/sda16-8-582   [000] ...1  1495.743927: ext4_es_lookup_extent_enter: dev 259,13 ino 8 lblk 68
    jbd2/sda16-8-582   [000] ...1  1495.743930: ext4_es_lookup_extent_exit: dev 259,13 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-582   [000] ...1  1495.743934: ext4_ext_map_blocks_enter: dev 259,13 ino 8 lblk 68 len 1 flags
    jbd2/sda16-8-582   [000] ...1  1495.743939: ext4_ext_show_extent: dev 259,13 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-582   [000] ...1  1495.743943: ext4_ext_map_blocks_exit: dev 259,13 ino 8 flags  lblk 68 pblk 591 len 1 mflags M ret 1
    jbd2/sda16-8-582   [000] ...1  1495.743947: ext4_es_insert_extent: dev 259,13 ino 8 es [68/1) mapped 591 status W
    jbd2/sda16-8-582   [000] ...1  1495.743996: ext4_es_lookup_extent_enter: dev 259,13 ino 8 lblk 69
    jbd2/sda16-8-582   [000] ...1  1495.743997: ext4_es_lookup_extent_exit: dev 259,13 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-582   [000] ...1  1495.743998: ext4_ext_map_blocks_enter: dev 259,13 ino 8 lblk 69 len 1 flags
    jbd2/sda16-8-582   [000] ...1  1495.744000: ext4_ext_show_extent: dev 259,13 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-582   [000] ...1  1495.744001: ext4_ext_map_blocks_exit: dev 259,13 ino 8 flags  lblk 69 pblk 592 len 1 mflags M ret 1
    jbd2/sda16-8-582   [000] ...1  1495.744003: ext4_es_insert_extent: dev 259,13 ino 8 es [69/1) mapped 592 status W
    jbd2/sda16-8-582   [000] ...1  1495.744015: ext4_es_lookup_extent_enter: dev 259,13 ino 8 lblk 70
    jbd2/sda16-8-582   [000] ...1  1495.744017: ext4_es_lookup_extent_exit: dev 259,13 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-582   [000] ...1  1495.744018: ext4_ext_map_blocks_enter: dev 259,13 ino 8 lblk 70 len 1 flags
    jbd2/sda16-8-582   [000] ...1  1495.744019: ext4_ext_show_extent: dev 259,13 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-582   [000] ...1  1495.744021: ext4_ext_map_blocks_exit: dev 259,13 ino 8 flags  lblk 70 pblk 593 len 1 mflags M ret 1
    jbd2/sda16-8-582   [000] ...1  1495.744021: ext4_es_insert_extent: dev 259,13 ino 8 es [70/1) mapped 593 status W
    jbd2/sda16-8-582   [000] ...1  1495.744027: ext4_es_lookup_extent_enter: dev 259,13 ino 8 lblk 71
    jbd2/sda16-8-582   [000] ...1  1495.744028: ext4_es_lookup_extent_exit: dev 259,13 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-582   [000] ...1  1495.744030: ext4_ext_map_blocks_enter: dev 259,13 ino 8 lblk 71 len 1 flags
    jbd2/sda16-8-582   [000] ...1  1495.744031: ext4_ext_show_extent: dev 259,13 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-582   [000] ...1  1495.744032: ext4_ext_map_blocks_exit: dev 259,13 ino 8 flags  lblk 71 pblk 594 len 1 mflags M ret 1
    jbd2/sda16-8-582   [000] ...1  1495.744033: ext4_es_insert_extent: dev 259,13 ino 8 es [71/1) mapped 594 status W
    jbd2/sda16-8-582   [000] ...1  1495.744038: ext4_es_lookup_extent_enter: dev 259,13 ino 8 lblk 72
    jbd2/sda16-8-582   [000] ...1  1495.744040: ext4_es_lookup_extent_exit: dev 259,13 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-582   [000] ...1  1495.744041: ext4_ext_map_blocks_enter: dev 259,13 ino 8 lblk 72 len 1 flags
    jbd2/sda16-8-582   [000] ...1  1495.744042: ext4_ext_show_extent: dev 259,13 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-582   [000] ...1  1495.744043: ext4_ext_map_blocks_exit: dev 259,13 ino 8 flags  lblk 72 pblk 595 len 1 mflags M ret 1
    jbd2/sda16-8-582   [000] ...1  1495.744044: ext4_es_insert_extent: dev 259,13 ino 8 es [72/1) mapped 595 status W
    jbd2/sda16-8-582   [000] ...1  1495.744049: ext4_es_lookup_extent_enter: dev 259,13 ino 8 lblk 73
    jbd2/sda16-8-582   [000] ...1  1495.744050: ext4_es_lookup_extent_exit: dev 259,13 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-582   [000] ...1  1495.744051: ext4_ext_map_blocks_enter: dev 259,13 ino 8 lblk 73 len 1 flags
    jbd2/sda16-8-582   [000] ...1  1495.744053: ext4_ext_show_extent: dev 259,13 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-582   [000] ...1  1495.744054: ext4_ext_map_blocks_exit: dev 259,13 ino 8 flags  lblk 73 pblk 596 len 1 mflags M ret 1
    jbd2/sda16-8-582   [000] ...1  1495.744055: ext4_es_insert_extent: dev 259,13 ino 8 es [73/1) mapped 596 status W
    jbd2/sda16-8-582   [000] ...1  1495.744465: ext4_es_lookup_extent_enter: dev 259,13 ino 8 lblk 74
    jbd2/sda16-8-582   [000] ...1  1495.744466: ext4_es_lookup_extent_exit: dev 259,13 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-582   [000] ...1  1495.744468: ext4_ext_map_blocks_enter: dev 259,13 ino 8 lblk 74 len 1 flags
    jbd2/sda16-8-582   [000] ...1  1495.744469: ext4_ext_show_extent: dev 259,13 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-582   [000] ...1  1495.744471: ext4_ext_map_blocks_exit: dev 259,13 ino 8 flags  lblk 74 pblk 597 len 1 mflags M ret 1
    jbd2/sda16-8-582   [000] ...1  1495.744472: ext4_es_insert_extent: dev 259,13 ino 8 es [74/1) mapped 597 status W
    jbd2/sda16-8-582   [000] ...3  1495.745339: jbd2_checkpoint_stats: dev 259,13 tid 68 chp_time 0 forced_to_close 0 written 0 dropped 5
    jbd2/sda16-8-582   [000] ...3  1495.745345: jbd2_drop_transaction: dev 259,13 transaction 68 sync 0
    jbd2/sda16-8-582   [000] ...2  1495.745352: jbd2_run_stats: dev 259,13 tid 69 wait 0 request_delay 0 running 10 locked 0 flushing 0 logging 0 handle_count 4 blocks 5 blocks_logged 6
    jbd2/sda16-8-582   [000] ...1  1495.745357: jbd2_end_commit: dev 259,13 transaction 69 sync 0 head 60
  test-open-writ-4930  [001] ...1  1495.745396: ext4_sync_file_exit: dev 259,13 ino 16 ret 0
  test-open-writ-4930  [001] ...1  1495.746460: ext4_discard_preallocations: dev 259,13 ino 16
   kworker/u16:4-352   [001] ...1  1500.744633: ext4_writepages: dev 259,13 ino 16 nr_to_write 13312 pages_skipped 0 range_start 0 range_end 9223372036854775807 sync_mode 0 for_kupdate 1 range_cyclic 1 writeback_index 1
   kworker/u16:4-352   [001] ...1  1500.744799: ext4_writepages_result: dev 259,13 ino 16 ret 0 pages_written 0 pages_skipped 0 sync_mode 0 writeback_index 1
```