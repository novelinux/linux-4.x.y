# JBD2 LOGS

```
# echo "hello world" > /cache/hello.txt
```

## JBD2

```
             sh-5263  [001] ...1  2320.735654: jbd2_handle_start: dev 259,0 tid 14 type 4 line_no 2460 requested_blocks 35
              sh-5263  [001] ...1  2320.736198: jbd2_handle_stats: dev 259,0 tid 14 type 4 line_no 2460 interval 0 sync 0 requested_blocks 35 dirtied_blocks 4
              sh-5263  [001] ...1  2320.736535: jbd2_handle_start: dev 259,0 tid 14 type 2 line_no 2765 requested_blocks 1
              sh-5263  [001] ...1  2320.736701: jbd2_handle_stats: dev 259,0 tid 14 type 2 line_no 2765 interval 0 sync 0 requested_blocks 1 dirtied_blocks 0
   kworker/u16:3-5354  [001] ...1  2322.365504: jbd2_handle_start: dev 259,0 tid 14 type 2 line_no 2573 requested_blocks 8
   kworker/u16:3-5354  [001] ...1  2322.365957: jbd2_handle_stats: dev 259,0 tid 14 type 2 line_no 2573 interval 0 sync 0 requested_blocks 8 dirtied_blocks 1
   kworker/u16:3-5354  [001] ...1  2322.366000: jbd2_handle_start: dev 259,0 tid 14 type 2 line_no 2573 requested_blocks 8
   kworker/u16:3-5354  [001] ...1  2322.366006: jbd2_handle_stats: dev 259,0 tid 14 type 2 line_no 2573 interval 0 sync 0 requested_blocks 8 dirtied_blocks 0
    jbd2/sda16-8-582   [001] ...1  2326.023595: jbd2_start_commit: dev 259,0 transaction 14 sync 0
    jbd2/sda16-8-582   [001] ...2  2326.023745: jbd2_commit_locking: dev 259,0 transaction 14 sync 0
    jbd2/sda16-8-582   [001] ...2  2326.023795: jbd2_commit_flushing: dev 259,0 transaction 14 sync 0
    jbd2/sda16-8-582   [001] ...1  2326.023826: jbd2_commit_logging: dev 259,0 transaction 14 sync 0
    jbd2/sda16-8-582   [001] ...2  2326.039558: jbd2_run_stats: dev 259,0 tid 14 wait 0 request_delay 0 running 5290 locked 0 flushing 0 logging 10 handle_count 4 blocks 5 blocks_logged 6
    jbd2/sda16-8-582   [001] ...1  2326.039647: jbd2_end_commit: dev 259,0 transaction 14 sync 0 head 10
```

## Full

```
              sh-5263  [001] ...1  2718.524838: ext4_request_inode: dev 259,0 dir 2 mode 0100666
              sh-5263  [001] ...1  2718.526294: ext4_journal_start: dev 259,0 blocks, 35 rsv_blocks, 0 caller __ext4_new_inode+0x750/0x1338
              sh-5263  [001] ...1  2718.526406: jbd2_handle_start: dev 259,0 tid 17 type 4 line_no 2460 requested_blocks 35
              sh-5263  [001] ...1  2718.526672: ext4_mark_inode_dirty: dev 259,0 ino 16 caller ext4_ext_tree_init+0x24/0x30
              sh-5263  [001] ...1  2718.526685: ext4_mark_inode_dirty: dev 259,0 ino 16 caller __ext4_new_inode+0x1108/0x1338
              sh-5263  [001] ...1  2718.526697: ext4_allocate_inode: dev 259,0 ino 16 dir 2 mode 0100666
              sh-5263  [001] ...1  2718.526726: ext4_es_lookup_extent_enter: dev 259,0 ino 2 lblk 0
              sh-5263  [001] ...1  2718.526738: ext4_es_lookup_extent_exit: dev 259,0 ino 2 found 1 [0/1) 1549 W0x10
              sh-5263  [001] ...1  2718.526782: ext4_mark_inode_dirty: dev 259,0 ino 2 caller add_dirent_to_buf+0x170/0x1dc
              sh-5263  [001] ...1  2718.526802: ext4_mark_inode_dirty: dev 259,0 ino 16 caller ext4_add_nondir+0x34/0x7c
              sh-5263  [001] ...1  2718.526839: jbd2_handle_stats: dev 259,0 tid 17 type 4 line_no 2460 interval 0 sync 0 requested_blocks 35 dirtied_blocks 4
              sh-5263  [001] ...1  2718.527155: ext4_da_write_begin: dev 259,0 ino 16 pos 0 len 12 flags 0
              sh-5263  [001] ...1  2718.527217: ext4_journal_start: dev 259,0 blocks, 1 rsv_blocks, 0 caller ext4_da_write_begin+0x1d4/0x304
              sh-5263  [001] ...1  2718.527225: jbd2_handle_start: dev 259,0 tid 17 type 2 line_no 2765 requested_blocks 1
              sh-5263  [001] ...1  2718.527250: ext4_es_lookup_extent_enter: dev 259,0 ino 16 lblk 0
              sh-5263  [001] ...1  2718.527254: ext4_es_lookup_extent_exit: dev 259,0 ino 16 found 0 [0/0) 0
              sh-5263  [001] ...1  2718.527268: ext4_ext_map_blocks_enter: dev 259,0 ino 16 lblk 0 len 1 flags
              sh-5263  [001] ...1  2718.527288: ext4_es_find_delayed_extent_range_enter: dev 259,0 ino 16 lblk 0
              sh-5263  [001] ...1  2718.527299: ext4_es_find_delayed_extent_range_exit: dev 259,0 ino 16 es [0/0) mapped 0 status
              sh-5263  [001] ...1  2718.527311: ext4_es_insert_extent: dev 259,0 ino 16 es [0/4294967295) mapped 576460752303423487 status H
              sh-5263  [001] ...1  2718.527342: ext4_ext_map_blocks_exit: dev 259,0 ino 16 flags  lblk 0 pblk 18446743800692538064 len 1 mflags  ret 0
              sh-5263  [001] ...2  2718.527357: ext4_da_reserve_space: dev 259,0 ino 16 mode 0100666 i_blocks 0 reserved_data_blocks 1 reserved_meta_blocks 0
              sh-5263  [001] ...1  2718.527361: ext4_es_insert_extent: dev 259,0 ino 16 es [0/1) mapped 576460752303423487 status D
              sh-5263  [001] ...1  2718.527403: ext4_da_write_end: dev 259,0 ino 16 pos 0 len 12 copied 12
              sh-5263  [001] ...1  2718.527460: ext4_journal_start: dev 259,0 blocks, 2 rsv_blocks, 0 caller ext4_dirty_inode+0x30/0x68
              sh-5263  [001] ...1  2718.527465: ext4_mark_inode_dirty: dev 259,0 ino 16 caller ext4_dirty_inode+0x44/0x68
              sh-5263  [001] ...1  2718.527481: jbd2_handle_stats: dev 259,0 tid 17 type 2 line_no 2765 interval 0 sync 0 requested_blocks 1 dirtied_blocks 0
   kworker/u16:5-4647  [001] ...1  2723.534298: ext4_writepages: dev 259,0 ino 16 nr_to_write 9216 pages_skipped 0 range_start 0 range_end 9223372036854775807 sync_mode 0 for_kupdate 1 range_cyclic 1 writeback_index 0
   kworker/u16:5-4647  [001] ...1  2723.534485: ext4_journal_start: dev 259,0 blocks, 8 rsv_blocks, 0 caller ext4_writepages+0x524/0xd24
   kworker/u16:5-4647  [001] ...1  2723.534525: jbd2_handle_start: dev 259,0 tid 17 type 2 line_no 2573 requested_blocks 8
   kworker/u16:5-4647  [001] ...1  2723.534533: ext4_da_write_pages: dev 259,0 ino 16 first_page 0 nr_to_write 9216 sync_mode 0
   kworker/u16:5-4647  [001] ...1  2723.534578: ext4_da_write_pages_extent: dev 259,0 ino 16 lblk 0 len 1 flags 0x200
   kworker/u16:5-4647  [001] ...1  2723.534594: ext4_es_lookup_extent_enter: dev 259,0 ino 16 lblk 0
   kworker/u16:5-4647  [001] ...1  2723.534605: ext4_es_lookup_extent_exit: dev 259,0 ino 16 found 1 [0/1) 576460752303423487 D0x10
   kworker/u16:5-4647  [001] ...1  2723.534624: ext4_ext_map_blocks_enter: dev 259,0 ino 16 lblk 0 len 1 flags CREATE|DELALLOC|METADATA_NOFAIL
   kworker/u16:5-4647  [001] ...1  2723.534671: ext4_request_blocks: dev 259,0 ino 16 flags HINT_DATA|DELALLOC_RESV|USE_RESV len 1 lblk 0 goal 0 lleft 0 lright 0 pleft 0 pright 0
   kworker/u16:5-4647  [001] ...1  2723.534897: ext4_mballoc_alloc: dev 259,0 inode 16 orig 0/0/1@0 goal 0/0/1@0 result 0/1555/1@0 blks 1 grps 1 cr 1 flags HINT_DATA|HINT_NOPREALLOC|DELALLOC_RESV|USE_RESV tail 0 broken 0
   kworker/u16:5-4647  [001] ...1  2723.534917: ext4_allocate_blocks: dev 259,0 ino 16 flags HINT_DATA|DELALLOC_RESV|USE_RESV len 1 block 1555 lblk 0 goal 0 lleft 0 lright 0 pleft 0 pright 0
   kworker/u16:5-4647  [001] ...1  2723.534947: ext4_mark_inode_dirty: dev 259,0 ino 16 caller __ext4_ext_dirty+0x6c/0x78
   kworker/u16:5-4647  [001] ...1  2723.534999: ext4_get_reserved_cluster_alloc: dev 259,0 ino 16 lblk 0 len 1
   kworker/u16:5-4647  [001] ...2  2723.535010: ext4_da_update_reserve_space: dev 259,0 ino 16 mode 0100666 i_blocks 0 used_blocks 1 reserved_data_blocks 1 reserved_meta_blocks 0 allocated_meta_blocks 0 quota_claim 1
   kworker/u16:5-4647  [001] ...1  2723.535022: ext4_journal_start: dev 259,0 blocks, 2 rsv_blocks, 0 caller ext4_dirty_inode+0x30/0x68
   kworker/u16:5-4647  [001] ...1  2723.535028: ext4_mark_inode_dirty: dev 259,0 ino 16 caller ext4_dirty_inode+0x44/0x68
   kworker/u16:5-4647  [001] ...1  2723.535051: ext4_discard_preallocations: dev 259,0 ino 16
   kworker/u16:5-4647  [001] ...1  2723.535068: ext4_ext_map_blocks_exit: dev 259,0 ino 16 flags CREATE|DELALLOC|METADATA_NOFAIL lblk 0 pblk 1555 len 1 mflags NM ret 1
   kworker/u16:5-4647  [001] ...1  2723.535083: ext4_es_insert_extent: dev 259,0 ino 16 es [0/1) mapped 1555 status W
   kworker/u16:5-4647  [001] ...1  2723.535224: ext4_mark_inode_dirty: dev 259,0 ino 16 caller ext4_writepages+0xc1c/0xd24
   kworker/u16:5-4647  [001] ...1  2723.535243: jbd2_handle_stats: dev 259,0 tid 17 type 2 line_no 2573 interval 0 sync 0 requested_blocks 8 dirtied_blocks 1
   kworker/u16:5-4647  [001] ...1  2723.535455: ext4_journal_start: dev 259,0 blocks, 8 rsv_blocks, 0 caller ext4_writepages+0x524/0xd24
   kworker/u16:5-4647  [001] ...1  2723.535463: jbd2_handle_start: dev 259,0 tid 17 type 2 line_no 2573 requested_blocks 8
   kworker/u16:5-4647  [001] ...1  2723.535467: ext4_da_write_pages: dev 259,0 ino 16 first_page 1 nr_to_write 9215 sync_mode 0
   kworker/u16:5-4647  [001] ...1  2723.535473: jbd2_handle_stats: dev 259,0 tid 17 type 2 line_no 2573 interval 0 sync 0 requested_blocks 8 dirtied_blocks 0
   kworker/u16:5-4647  [001] ...1  2723.535493: ext4_writepages_result: dev 259,0 ino 16 ret 0 pages_written 1 pages_skipped 0 sync_mode 0 writeback_index 1
    jbd2/sda16-8-582   [001] ...1  2723.535777: jbd2_start_commit: dev 259,0 transaction 17 sync 0
    jbd2/sda16-8-582   [001] ...2  2723.535786: jbd2_commit_locking: dev 259,0 transaction 17 sync 0
    jbd2/sda16-8-582   [001] ...2  2723.535827: jbd2_commit_flushing: dev 259,0 transaction 17 sync 0
    jbd2/sda16-8-582   [001] ...1  2723.535857: jbd2_commit_logging: dev 259,0 transaction 17 sync 0
    jbd2/sda16-8-582   [001] ...1  2723.535881: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 42
    jbd2/sda16-8-582   [001] ...1  2723.535890: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-582   [001] ...1  2723.535899: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 42 len 1 flags
    jbd2/sda16-8-582   [001] ...1  2723.535912: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-582   [001] ...1  2723.535919: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 42 pblk 565 len 1 mflags M ret 1
    jbd2/sda16-8-582   [001] ...1  2723.535925: ext4_es_insert_extent: dev 259,0 ino 8 es [42/1) mapped 565 status W
    jbd2/sda16-8-582   [001] ...1  2723.536065: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 43
    jbd2/sda16-8-582   [001] ...1  2723.536069: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-582   [001] ...1  2723.536075: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 43 len 1 flags
    jbd2/sda16-8-582   [001] ...1  2723.536081: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-582   [001] ...1  2723.536086: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 43 pblk 566 len 1 mflags M ret 1
    jbd2/sda16-8-582   [001] ...1  2723.536090: ext4_es_insert_extent: dev 259,0 ino 8 es [43/1) mapped 566 status W
    jbd2/sda16-8-582   [001] ...1  2723.536120: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 44
    jbd2/sda16-8-582   [001] ...1  2723.536125: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-582   [001] ...1  2723.536129: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 44 len 1 flags
    jbd2/sda16-8-582   [001] ...1  2723.536134: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-582   [001] ...1  2723.536149: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 44 pblk 567 len 1 mflags M ret 1
    jbd2/sda16-8-582   [001] ...1  2723.536155: ext4_es_insert_extent: dev 259,0 ino 8 es [44/1) mapped 567 status W
    jbd2/sda16-8-582   [001] ...1  2723.536166: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 45
    jbd2/sda16-8-582   [001] ...1  2723.536172: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-582   [001] ...1  2723.536176: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 45 len 1 flags
    jbd2/sda16-8-582   [001] ...1  2723.536181: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-582   [001] ...1  2723.536186: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 45 pblk 568 len 1 mflags M ret 1
    jbd2/sda16-8-582   [001] ...1  2723.536190: ext4_es_insert_extent: dev 259,0 ino 8 es [45/1) mapped 568 status W
    jbd2/sda16-8-582   [001] ...1  2723.536204: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 46
    jbd2/sda16-8-582   [001] ...1  2723.536207: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-582   [001] ...1  2723.536212: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 46 len 1 flags
    jbd2/sda16-8-582   [001] ...1  2723.536217: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-582   [001] ...1  2723.536222: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 46 pblk 569 len 1 mflags M ret 1
    jbd2/sda16-8-582   [001] ...1  2723.536226: ext4_es_insert_extent: dev 259,0 ino 8 es [46/1) mapped 569 status W
    jbd2/sda16-8-582   [001] ...1  2723.536239: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 47
    jbd2/sda16-8-582   [001] ...1  2723.536244: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-582   [001] ...1  2723.536248: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 47 len 1 flags
    jbd2/sda16-8-582   [001] ...1  2723.536253: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-582   [001] ...1  2723.536258: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 47 pblk 570 len 1 mflags M ret 1
    jbd2/sda16-8-582   [001] ...1  2723.536262: ext4_es_insert_extent: dev 259,0 ino 8 es [47/1) mapped 570 status W
    jbd2/sda16-8-582   [001] ...1  2723.557546: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 48
    jbd2/sda16-8-582   [001] ...1  2723.557655: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-582   [001] ...1  2723.557669: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 48 len 1 flags
    jbd2/sda16-8-582   [001] ...1  2723.557677: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-582   [001] ...1  2723.557686: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 48 pblk 571 len 1 mflags M ret 1
    jbd2/sda16-8-582   [001] ...1  2723.557693: ext4_es_insert_extent: dev 259,0 ino 8 es [48/1) mapped 571 status W
    jbd2/sda16-8-582   [001] ...2  2723.558982: jbd2_run_stats: dev 259,0 tid 17 wait 0 request_delay 0 running 5010 locked 0 flushing 0 logging 20 handle_count 4 blocks 5 blocks_logged 6
    jbd2/sda16-8-582   [001] ...1  2723.559060: jbd2_end_commit: dev 259,0 transaction 17 sync 0 head 10
```

## write O_SYNC

```
test-5852  [000] ...1  5232.025752: ext4_request_inode: dev 259,0 dir 2 mode 0104620
            test-5852  [000] ...1  5232.025952: ext4_journal_start: dev 259,0 blocks, 35 rsv_blocks, 0 caller __ext4_new_inode+0x750/0x1338
            test-5852  [000] ...1  5232.025989: jbd2_handle_start: dev 259,0 tid 20 type 4 line_no 2460 requested_blocks 35
            test-5852  [000] ...1  5232.026163: ext4_mark_inode_dirty: dev 259,0 ino 16 caller ext4_ext_tree_init+0x24/0x30
            test-5852  [000] ...1  5232.026168: ext4_mark_inode_dirty: dev 259,0 ino 16 caller __ext4_new_inode+0x1108/0x1338
            test-5852  [000] ...1  5232.026173: ext4_allocate_inode: dev 259,0 ino 16 dir 2 mode 0104620
            test-5852  [000] ...1  5232.026193: ext4_es_lookup_extent_enter: dev 259,0 ino 2 lblk 0
            test-5852  [000] ...1  5232.026199: ext4_es_lookup_extent_exit: dev 259,0 ino 2 found 1 [0/1) 1549 W0x10
            test-5852  [000] ...1  5232.026226: ext4_mark_inode_dirty: dev 259,0 ino 2 caller add_dirent_to_buf+0x170/0x1dc
            test-5852  [000] ...1  5232.026236: ext4_mark_inode_dirty: dev 259,0 ino 16 caller ext4_add_nondir+0x34/0x7c
            test-5852  [000] ...1  5232.026257: jbd2_handle_stats: dev 259,0 tid 20 type 4 line_no 2460 interval 0 sync 0 requested_blocks 35 dirtied_blocks 4
    jbd2/sda16-8-582   [000] ...1  5237.053674: jbd2_start_commit: dev 259,0 transaction 20 sync 0
    jbd2/sda16-8-582   [000] ...2  5237.053821: jbd2_commit_locking: dev 259,0 transaction 20 sync 0
    jbd2/sda16-8-582   [000] ...3  5237.053872: jbd2_checkpoint_stats: dev 259,0 tid 18 chp_time 0 forced_to_close 0 written 0 dropped 5
    jbd2/sda16-8-582   [000] ...3  5237.053885: jbd2_drop_transaction: dev 259,0 transaction 18 sync 0
    jbd2/sda16-8-582   [000] ...2  5237.053930: jbd2_commit_flushing: dev 259,0 transaction 20 sync 0
    jbd2/sda16-8-582   [000] ...1  5237.053961: jbd2_commit_logging: dev 259,0 transaction 20 sync 0
    jbd2/sda16-8-582   [000] ...1  5237.053997: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 65
    jbd2/sda16-8-582   [000] ...1  5237.054011: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-582   [000] ...1  5237.054030: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 65 len 1 flags
    jbd2/sda16-8-582   [000] ...1  5237.054056: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-582   [000] ...1  5237.054077: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 65 pblk 588 len 1 mflags M ret 1
    jbd2/sda16-8-582   [000] ...1  5237.054091: ext4_es_insert_extent: dev 259,0 ino 8 es [65/1) mapped 588 status W
    jbd2/sda16-8-582   [000] ...1  5237.054280: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 66
    jbd2/sda16-8-582   [000] ...1  5237.054285: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-582   [000] ...1  5237.054290: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 66 len 1 flags
    jbd2/sda16-8-582   [000] ...1  5237.054296: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-582   [000] ...1  5237.054300: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 66 pblk 589 len 1 mflags M ret 1
    jbd2/sda16-8-582   [000] ...1  5237.054305: ext4_es_insert_extent: dev 259,0 ino 8 es [66/1) mapped 589 status W
    jbd2/sda16-8-582   [000] ...1  5237.054343: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 67
    jbd2/sda16-8-582   [000] ...1  5237.054348: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-582   [000] ...1  5237.054352: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 67 len 1 flags
    jbd2/sda16-8-582   [000] ...1  5237.054358: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-582   [000] ...1  5237.054363: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 67 pblk 590 len 1 mflags M ret 1
    jbd2/sda16-8-582   [000] ...1  5237.054368: ext4_es_insert_extent: dev 259,0 ino 8 es [67/1) mapped 590 status W
    jbd2/sda16-8-582   [000] ...1  5237.054383: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 68
    jbd2/sda16-8-582   [000] ...1  5237.054387: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-582   [000] ...1  5237.054391: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 68 len 1 flags
    jbd2/sda16-8-582   [000] ...1  5237.054396: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-582   [000] ...1  5237.054400: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 68 pblk 591 len 1 mflags M ret 1
    jbd2/sda16-8-582   [000] ...1  5237.054404: ext4_es_insert_extent: dev 259,0 ino 8 es [68/1) mapped 591 status W
    jbd2/sda16-8-582   [000] ...1  5237.054418: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 69
    jbd2/sda16-8-582   [000] ...1  5237.054423: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-582   [000] ...1  5237.054427: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 69 len 1 flags
    jbd2/sda16-8-582   [000] ...1  5237.054432: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-582   [000] ...1  5237.054436: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 69 pblk 592 len 1 mflags M ret 1
    jbd2/sda16-8-582   [000] ...1  5237.054440: ext4_es_insert_extent: dev 259,0 ino 8 es [69/1) mapped 592 status W
    jbd2/sda16-8-582   [000] ...1  5237.078061: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 70
    jbd2/sda16-8-582   [000] ...1  5237.078164: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-582   [000] ...1  5237.078179: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 70 len 1 flags
    jbd2/sda16-8-582   [000] ...1  5237.078190: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-582   [000] ...1  5237.078199: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 70 pblk 593 len 1 mflags M ret 1
    jbd2/sda16-8-582   [000] ...1  5237.078206: ext4_es_insert_extent: dev 259,0 ino 8 es [70/1) mapped 593 status W
    jbd2/sda16-8-582   [000] ...2  5237.084212: jbd2_run_stats: dev 259,0 tid 20 wait 0 request_delay 0 running 5030 locked 0 flushing 0 logging 30 handle_count 1 blocks 4 blocks_logged 5
    jbd2/sda16-8-582   [000] ...1  5237.084270: jbd2_end_commit: dev 259,0 transaction 20 sync 0 head 10
```

## fsync - nobarrier

```
            test-5881  [000] ...1  5415.306999: ext4_request_inode: dev 259,0 dir 2 mode 0103600
            test-5881  [000] ...1  5415.307179: ext4_journal_start: dev 259,0 blocks, 35 rsv_blocks, 0 caller __ext4_new_inode+0x750/0x1338
            test-5881  [000] ...1  5415.307215: jbd2_handle_start: dev 259,0 tid 23 type 4 line_no 2460 requested_blocks 35
            test-5881  [000] ...1  5415.307386: ext4_mark_inode_dirty: dev 259,0 ino 16 caller ext4_ext_tree_init+0x24/0x30
            test-5881  [000] ...1  5415.307391: ext4_mark_inode_dirty: dev 259,0 ino 16 caller __ext4_new_inode+0x1108/0x1338
            test-5881  [000] ...1  5415.307395: ext4_allocate_inode: dev 259,0 ino 16 dir 2 mode 0103600
            test-5881  [000] ...1  5415.307415: ext4_es_lookup_extent_enter: dev 259,0 ino 2 lblk 0
            test-5881  [000] ...1  5415.307422: ext4_es_lookup_extent_exit: dev 259,0 ino 2 found 1 [0/1) 1549 W0x10
            test-5881  [000] ...1  5415.307446: ext4_mark_inode_dirty: dev 259,0 ino 2 caller add_dirent_to_buf+0x170/0x1dc
            test-5881  [000] ...1  5415.307456: ext4_mark_inode_dirty: dev 259,0 ino 16 caller ext4_add_nondir+0x34/0x7c
            test-5881  [000] ...1  5415.307477: jbd2_handle_stats: dev 259,0 tid 23 type 4 line_no 2460 interval 0 sync 0 requested_blocks 35 dirtied_blocks 4
            test-5881  [000] ...1  5415.307515: ext4_sync_file_enter: dev 259,0 ino 16 parent 2 datasync 0
    jbd2/sda16-8-582   [002] ...1  5415.308643: jbd2_start_commit: dev 259,0 transaction 23 sync 0
    jbd2/sda16-8-582   [002] ...2  5415.308669: jbd2_commit_locking: dev 259,0 transaction 23 sync 0
    jbd2/sda16-8-582   [002] ...3  5415.308698: jbd2_checkpoint_stats: dev 259,0 tid 21 chp_time 0 forced_to_close 0 written 0 dropped 5
    jbd2/sda16-8-582   [002] ...3  5415.308707: jbd2_drop_transaction: dev 259,0 transaction 21 sync 0
    jbd2/sda16-8-582   [002] ...2  5415.308728: jbd2_commit_flushing: dev 259,0 transaction 23 sync 0
    jbd2/sda16-8-582   [002] ...1  5415.308742: jbd2_commit_logging: dev 259,0 transaction 23 sync 0
    jbd2/sda16-8-582   [002] ...1  5415.308760: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 87
    jbd2/sda16-8-582   [002] ...1  5415.308765: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-582   [002] ...1  5415.308777: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 87 len 1 flags
    jbd2/sda16-8-582   [002] ...1  5415.308792: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-582   [002] ...1  5415.308800: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 87 pblk 610 len 1 mflags M ret 1
    jbd2/sda16-8-582   [002] ...1  5415.308809: ext4_es_insert_extent: dev 259,0 ino 8 es [87/1) mapped 610 status W
    jbd2/sda16-8-582   [002] ...1  5415.308903: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 88
    jbd2/sda16-8-582   [002] ...1  5415.308904: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-582   [002] ...1  5415.308906: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 88 len 1 flags
    jbd2/sda16-8-582   [002] ...1  5415.308906: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-582   [002] ...1  5415.308909: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 88 pblk 611 len 1 mflags M ret 1
    jbd2/sda16-8-582   [002] ...1  5415.308911: ext4_es_insert_extent: dev 259,0 ino 8 es [88/1) mapped 611 status W
    jbd2/sda16-8-582   [002] ...1  5415.308926: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 89
    jbd2/sda16-8-582   [002] ...1  5415.308928: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-582   [002] ...1  5415.308929: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 89 len 1 flags
    jbd2/sda16-8-582   [002] ...1  5415.308929: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-582   [002] ...1  5415.308931: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 89 pblk 612 len 1 mflags M ret 1
    jbd2/sda16-8-582   [002] ...1  5415.308932: ext4_es_insert_extent: dev 259,0 ino 8 es [89/1) mapped 612 status W
    jbd2/sda16-8-582   [002] ...1  5415.308936: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 90
    jbd2/sda16-8-582   [002] ...1  5415.308936: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-582   [002] ...1  5415.308937: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 90 len 1 flags
    jbd2/sda16-8-582   [002] ...1  5415.308939: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-582   [002] ...1  5415.308940: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 90 pblk 613 len 1 mflags M ret 1
    jbd2/sda16-8-582   [002] ...1  5415.308941: ext4_es_insert_extent: dev 259,0 ino 8 es [90/1) mapped 613 status W
    jbd2/sda16-8-582   [002] ...1  5415.308945: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 91
    jbd2/sda16-8-582   [002] ...1  5415.308947: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-582   [002] ...1  5415.308948: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 91 len 1 flags
    jbd2/sda16-8-582   [002] ...1  5415.308949: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-582   [002] ...1  5415.308950: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 91 pblk 614 len 1 mflags M ret 1
    jbd2/sda16-8-582   [002] ...1  5415.308951: ext4_es_insert_extent: dev 259,0 ino 8 es [91/1) mapped 614 status W
    jbd2/sda16-8-582   [002] ...1  5415.316644: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 92
    jbd2/sda16-8-582   [002] ...1  5415.316668: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-582   [002] ...1  5415.316671: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 92 len 1 flags
    jbd2/sda16-8-582   [002] ...1  5415.316674: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-582   [002] ...1  5415.316677: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 92 pblk 615 len 1 mflags M ret 1
    jbd2/sda16-8-582   [002] ...1  5415.316679: ext4_es_insert_extent: dev 259,0 ino 8 es [92/1) mapped 615 status W
    jbd2/sda16-8-582   [002] ...2  5415.317556: jbd2_run_stats: dev 259,0 tid 23 wait 0 request_delay 0 running 0 locked 0 flushing 0 logging 10 handle_count 1 blocks 4 blocks_logged 5
    jbd2/sda16-8-582   [002] ...1  5415.317576: jbd2_end_commit: dev 259,0 transaction 23 sync 0 head 10
            test-5881  [000] ...1  5415.317606: ext4_sync_file_exit: dev 259,0 ino 16 ret 0
```

## fsync - barrier

```
              sh-4461  [000] ...1    89.421404: ext4_es_lookup_extent_enter: dev 259,0 ino 17 lblk 0
              sh-4461  [000] ...1    89.421508: ext4_es_lookup_extent_exit: dev 259,0 ino 17 found 0 [0/0) 0
              sh-4461  [000] ...1    89.421517: ext4_ext_map_blocks_enter: dev 259,0 ino 17 lblk 0 len 2 flags
              sh-4461  [000] ...1    89.421529: ext4_ext_show_extent: dev 259,0 ino 17 lblk 0 pblk 1558 len 2
              sh-4461  [000] ...1    89.421538: ext4_ext_map_blocks_exit: dev 259,0 ino 17 flags  lblk 0 pblk 1558 len 2 mflags M ret 2
              sh-4461  [000] ...1    89.421546: ext4_es_insert_extent: dev 259,0 ino 17 es [0/2) mapped 1558 status W
            test-4461  [001] ...1    89.447318: ext4_es_lookup_extent_enter: dev 259,0 ino 2 lblk 0
            test-4461  [001] ...1    89.447413: ext4_es_lookup_extent_exit: dev 259,0 ino 2 found 1 [0/1) 1549 W0x10
            test-4461  [001] ...1    89.447788: ext4_request_inode: dev 259,0 dir 2 mode 0102100
            test-4461  [001] ...1    89.447827: ext4_load_inode_bitmap: dev 259,0 group 0
            test-4461  [001] ...1    89.454790: ext4_journal_start: dev 259,0 blocks, 35 rsv_blocks, 0 caller __ext4_new_inode+0x750/0x1338
            test-4461  [001] ...1    89.454848: jbd2_handle_start: dev 259,0 tid 26 type 4 line_no 2460 requested_blocks 35
            test-4461  [001] ...1    89.454966: ext4_mark_inode_dirty: dev 259,0 ino 18 caller ext4_ext_tree_init+0x24/0x30
            test-4461  [001] ...1    89.454974: ext4_mark_inode_dirty: dev 259,0 ino 18 caller __ext4_new_inode+0x1108/0x1338
            test-4461  [001] ...1    89.454978: ext4_allocate_inode: dev 259,0 ino 18 dir 2 mode 0102100
            test-4461  [001] ...1    89.454987: ext4_es_lookup_extent_enter: dev 259,0 ino 2 lblk 0
            test-4461  [001] ...1    89.454990: ext4_es_lookup_extent_exit: dev 259,0 ino 2 found 1 [0/1) 1549 W0x10
            test-4461  [001] ...1    89.455004: ext4_mark_inode_dirty: dev 259,0 ino 2 caller add_dirent_to_buf+0x170/0x1dc
            test-4461  [001] ...1    89.455014: ext4_mark_inode_dirty: dev 259,0 ino 18 caller ext4_add_nondir+0x34/0x7c
            test-4461  [001] ...1    89.455025: jbd2_handle_stats: dev 259,0 tid 26 type 4 line_no 2460 interval 0 sync 0 requested_blocks 35 dirtied_blocks 5
            test-4461  [001] ...1    89.455098: ext4_sync_file_enter: dev 259,0 ino 18 parent 2 datasync 0
           <...>-578   [002] ...1    89.455162: jbd2_start_commit: dev 259,0 transaction 26 sync 0
           <...>-578   [002] ...2    89.455165: jbd2_commit_locking: dev 259,0 transaction 26 sync 0
           <...>-578   [002] ...2    89.455177: jbd2_commit_flushing: dev 259,0 transaction 26 sync 0
           <...>-578   [002] ...1    89.455184: jbd2_commit_logging: dev 259,0 transaction 26 sync 0
           <...>-578   [002] ...1    89.455191: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 5
           <...>-578   [002] ...1    89.455193: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
           <...>-578   [002] ...1    89.455198: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 5 len 1 flags
           <...>-578   [002] ...1    89.455203: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
           <...>-578   [002] ...1    89.455206: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 5 pblk 528 len 1 mflags M ret 1
           <...>-578   [002] ...1    89.455210: ext4_es_insert_extent: dev 259,0 ino 8 es [5/1) mapped 528 status W
    jbd2/sda16-8-578   [002] ...1    89.455256: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 6
    jbd2/sda16-8-578   [002] ...1    89.455258: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-578   [002] ...1    89.455259: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 6 len 1 flags
    jbd2/sda16-8-578   [002] ...1    89.455260: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-578   [002] ...1    89.455261: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 6 pblk 529 len 1 mflags M ret 1
    jbd2/sda16-8-578   [002] ...1    89.455262: ext4_es_insert_extent: dev 259,0 ino 8 es [6/1) mapped 529 status W
    jbd2/sda16-8-578   [002] ...1    89.455269: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 7
    jbd2/sda16-8-578   [002] ...1    89.455270: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-578   [002] ...1    89.455271: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 7 len 1 flags
    jbd2/sda16-8-578   [002] ...1    89.455273: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-578   [002] ...1    89.455274: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 7 pblk 530 len 1 mflags M ret 1
    jbd2/sda16-8-578   [002] ...1    89.455275: ext4_es_insert_extent: dev 259,0 ino 8 es [7/1) mapped 530 status W
    jbd2/sda16-8-578   [002] ...1    89.455278: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 8
    jbd2/sda16-8-578   [002] ...1    89.455279: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-578   [002] ...1    89.455280: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 8 len 1 flags
    jbd2/sda16-8-578   [002] ...1    89.455281: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-578   [002] ...1    89.455282: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 8 pblk 531 len 1 mflags M ret 1
    jbd2/sda16-8-578   [002] ...1    89.455283: ext4_es_insert_extent: dev 259,0 ino 8 es [8/1) mapped 531 status W
    jbd2/sda16-8-578   [002] ...1    89.455287: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 9
    jbd2/sda16-8-578   [002] ...1    89.455288: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-578   [002] ...1    89.455289: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 9 len 1 flags
    jbd2/sda16-8-578   [002] ...1    89.455291: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-578   [002] ...1    89.455292: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 9 pblk 532 len 1 mflags M ret 1
    jbd2/sda16-8-578   [002] ...1    89.455293: ext4_es_insert_extent: dev 259,0 ino 8 es [9/1) mapped 532 status W
    jbd2/sda16-8-578   [002] ...1    89.455296: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 10
    jbd2/sda16-8-578   [002] ...1    89.455297: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-578   [002] ...1    89.455298: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 10 len 1 flags
    jbd2/sda16-8-578   [002] ...1    89.455299: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-578   [002] ...1    89.455300: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 10 pblk 533 len 1 mflags M ret 1
    jbd2/sda16-8-578   [002] ...1    89.455301: ext4_es_insert_extent: dev 259,0 ino 8 es [10/1) mapped 533 status W
    jbd2/sda16-8-578   [002] ...1    89.456042: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 11
    jbd2/sda16-8-578   [002] ...1    89.456044: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-578   [002] ...1    89.456045: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 11 len 1 flags
    jbd2/sda16-8-578   [002] ...1    89.456048: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-578   [002] ...1    89.456049: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 11 pblk 534 len 1 mflags M ret 1
    jbd2/sda16-8-578   [002] ...1    89.456050: ext4_es_insert_extent: dev 259,0 ino 8 es [11/1) mapped 534 status W
    jbd2/sda16-8-578   [002] ...2    89.456733: jbd2_run_stats: dev 259,0 tid 26 wait 0 request_delay 0 running 0 locked 0 flushing 0 logging 0 handle_count 1 blocks 5 blocks_logged 6
    jbd2/sda16-8-578   [002] ...1    89.456737: jbd2_end_commit: dev 259,0 transaction 26 sync 0 head 25
            test-4461  [001] ...1    89.456771: ext4_sync_file_exit: dev 259,0 ino 18 ret 0
```