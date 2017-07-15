# JBD2

## Test Code

```
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include <fcntl.h>
#include <unistd.h>

int main(int argc, char *argv[])
{
    char *filename = argv[1];

    int fd = open(filename, O_CREAT | O_RDWR);
    if (fd < 0) {
        printf("open %s failed: %s\n", filename, strerror(errno));
        return 1;
    }
    if (write(fd, "hello world\n", 12) != 12) {
        printf("write failed: %s\n", strerror(errno));
        return 1;
    }
    fsync(fd);

    return 0;
}
```

## open-write  - barrier

```
open:
  test-open-writ-9948  [000] ...1 22423.447216: ext4_request_inode: dev 259,0 dir 2 mode 0100700
  test-open-writ-9948  [000] ...1 22423.447440: ext4_journal_start: dev 259,0 blocks, 35 rsv_blocks, 0 caller __ext4_new_inode+0x750/0x1338
  test-open-writ-9948  [000] ...1 22423.447483: jbd2_handle_start: dev 259,0 tid 56 type 4 line_no 2460 requested_blocks 35
  test-open-writ-9948  [000] ...1 22423.447640: ext4_mark_inode_dirty: dev 259,0 ino 13 caller ext4_ext_tree_init+0x24/0x30
  test-open-writ-9948  [000] ...1 22423.447644: ext4_mark_inode_dirty: dev 259,0 ino 13 caller __ext4_new_inode+0x1108/0x1338
  test-open-writ-9948  [000] ...1 22423.447648: ext4_allocate_inode: dev 259,0 ino 13 dir 2 mode 0100700
  test-open-writ-9948  [000] ...1 22423.447667: ext4_es_lookup_extent_enter: dev 259,0 ino 2 lblk 0
  test-open-writ-9948  [000] ...1 22423.447675: ext4_es_lookup_extent_exit: dev 259,0 ino 2 found 1 [0/1) 1549 W0x10
  test-open-writ-9948  [000] ...1 22423.447703: ext4_mark_inode_dirty: dev 259,0 ino 2 caller add_dirent_to_buf+0x170/0x1dc
  test-open-writ-9948  [000] ...1 22423.447711: ext4_mark_inode_dirty: dev 259,0 ino 13 caller ext4_add_nondir+0x34/0x7c
  test-open-writ-9948  [000] ...1 22423.447734: jbd2_handle_stats: dev 259,0 tid 56 type 4 line_no 2460 interval 0 sync 0 requested_blocks 35 dirtied_blocks 4

write:
  test-open-writ-9948  [000] ...1 22423.447810: ext4_da_write_begin: dev 259,0 ino 13 pos 0 len 12 flags 0
  test-open-writ-9948  [000] ...1 22423.447834: ext4_journal_start: dev 259,0 blocks, 1 rsv_blocks, 0 caller ext4_da_write_begin+0x1d4/0x304
  test-open-writ-9948  [000] ...1 22423.447835: jbd2_handle_start: dev 259,0 tid 56 type 2 line_no 2765 requested_blocks 1
  test-open-writ-9948  [000] ...1 22423.447850: ext4_es_lookup_extent_enter: dev 259,0 ino 13 lblk 0
  test-open-writ-9948  [000] ...1 22423.447852: ext4_es_lookup_extent_exit: dev 259,0 ino 13 found 0 [0/0) 0

test-open-writ-9948  [000] ...1 22423.447860: ext4_ext_map_blocks_enter: dev 259,0 ino 13 lblk 0 len 1 flags
  test-open-writ-9948  [000] ...1 22423.447872: ext4_es_find_delayed_extent_range_enter: dev 259,0 ino 13 lblk 0
  test-open-writ-9948  [000] ...1 22423.447880: ext4_es_find_delayed_extent_range_exit: dev 259,0 ino 13 es [0/0) mapped 0 status
  test-open-writ-9948  [000] ...1 22423.447887: ext4_es_insert_extent: dev 259,0 ino 13 es [0/4294967295) mapped 576460752303423487 status H
  test-open-writ-9948  [000] ...1 22423.447909: ext4_ext_map_blocks_exit: dev 259,0 ino 13 flags  lblk 0 pblk 18446743803717991120 len 1 mflags  ret 0

  test-open-writ-9948  [000] ...2 22423.447919: ext4_da_reserve_space: dev 259,0 ino 13 mode 0100700 i_blocks 0 reserved_data_blocks 1 reserved_meta_blocks 0
  test-open-writ-9948  [000] ...1 22423.447920: ext4_es_insert_extent: dev 259,0 ino 13 es [0/1) mapped 576460752303423487 status D


  test-open-writ-9948  [000] ...1 22423.447950: ext4_da_write_end: dev 259,0 ino 13 pos 0 len 12 copied 12
  test-open-writ-9948  [000] ...1 22423.447974: ext4_journal_start: dev 259,0 blocks, 2 rsv_blocks, 0 caller ext4_dirty_inode+0x30/0x68
  test-open-writ-9948  [000] ...1 22423.447975: ext4_mark_inode_dirty: dev 259,0 ino 13 caller ext4_dirty_inode+0x44/0x68
  test-open-writ-9948  [000] ...1 22423.447978: jbd2_handle_stats: dev 259,0 tid 56 type 2 line_no 2765 interval 0 sync 0 requested_blocks 1 dirtied_blocks 0
   kworker/u16:8-9916  [000] ...1 22427.743227: ext4_writepages: dev 259,0 ino 13 nr_to_write 1024 pages_skipped 0 range_start 0 range_end 9223372036854775807 sync_mode 0 for_kupdate 1 range_cyclic 1 writeback_index 0
   kworker/u16:8-9916  [000] ...1 22427.743252: ext4_journal_start: dev 259,0 blocks, 8 rsv_blocks, 0 caller ext4_writepages+0x524/0xd24
   kworker/u16:8-9916  [000] ...1 22427.743268: jbd2_handle_start: dev 259,0 tid 56 type 2 line_no 2573 requested_blocks 8
   kworker/u16:8-9916  [000] ...1 22427.743272: ext4_da_write_pages: dev 259,0 ino 13 first_page 0 nr_to_write 1024 sync_mode 0
   kworker/u16:8-9916  [000] ...1 22427.743287: ext4_da_write_pages_extent: dev 259,0 ino 13 lblk 0 len 1 flags 0x200
   kworker/u16:8-9916  [000] ...1 22427.743302: ext4_es_lookup_extent_enter: dev 259,0 ino 13 lblk 0
   kworker/u16:8-9916  [000] ...1 22427.743317: ext4_es_lookup_extent_exit: dev 259,0 ino 13 found 1 [0/1) 576460752303423487 D0x10
   kworker/u16:8-9916  [000] ...1 22427.743336: ext4_ext_map_blocks_enter: dev 259,0 ino 13 lblk 0 len 1 flags CREATE|DELALLOC|METADATA_NOFAIL
   kworker/u16:8-9916  [000] ...1 22427.743380: ext4_request_blocks: dev 259,0 ino 13 flags HINT_DATA|DELALLOC_RESV|USE_RESV len 1 lblk 0 goal 0 lleft 0 lright 0 pleft 0 pright 0
   kworker/u16:8-9916  [000] ...1 22427.743608: ext4_mballoc_alloc: dev 259,0 inode 13 orig 0/0/1@0 goal 0/0/1@0 result 0/1555/1@0 blks 2 grps 1 cr 1 flags HINT_DATA|HINT_NOPREALLOC|DELALLOC_RESV|USE_RESV tail 0 broken 0
   kworker/u16:8-9916  [000] ...1 22427.743620: ext4_allocate_blocks: dev 259,0 ino 13 flags HINT_DATA|DELALLOC_RESV|USE_RESV len 1 block 1555 lblk 0 goal 0 lleft 0 lright 0 pleft 0 pright 0
   kworker/u16:8-9916  [000] ...1 22427.743650: ext4_mark_inode_dirty: dev 259,0 ino 13 caller __ext4_ext_dirty+0x6c/0x78
   kworker/u16:8-9916  [000] ...1 22427.743705: ext4_get_reserved_cluster_alloc: dev 259,0 ino 13 lblk 0 len 1
   kworker/u16:8-9916  [000] ...2 22427.743715: ext4_da_update_reserve_space: dev 259,0 ino 13 mode 0100700 i_blocks 0 used_blocks 1 reserved_data_blocks 1 reserved_meta_blocks 0 allocated_meta_blocks 0 quota_claim 1
   kworker/u16:8-9916  [000] ...1 22427.743728: ext4_journal_start: dev 259,0 blocks, 2 rsv_blocks, 0 caller ext4_dirty_inode+0x30/0x68
   kworker/u16:8-9916  [000] ...1 22427.743732: ext4_mark_inode_dirty: dev 259,0 ino 13 caller ext4_dirty_inode+0x44/0x68
   kworker/u16:8-9916  [000] ...1 22427.743755: ext4_discard_preallocations: dev 259,0 ino 13
   kworker/u16:8-9916  [000] ...1 22427.743771: ext4_ext_map_blocks_exit: dev 259,0 ino 13 flags CREATE|DELALLOC|METADATA_NOFAIL lblk 0 pblk 1555 len 1 mflags NM ret 1
   kworker/u16:8-9916  [000] ...1 22427.743786: ext4_es_insert_extent: dev 259,0 ino 13 es [0/1) mapped 1555 status W
   kworker/u16:8-9916  [000] ...1 22427.743857: ext4_mark_inode_dirty: dev 259,0 ino 13 caller ext4_writepages+0xc1c/0xd24
   kworker/u16:8-9916  [000] ...1 22427.743868: jbd2_handle_stats: dev 259,0 tid 56 type 2 line_no 2573 interval 0 sync 0 requested_blocks 8 dirtied_blocks 1
   kworker/u16:8-9916  [000] ...1 22427.743924: ext4_journal_start: dev 259,0 blocks, 8 rsv_blocks, 0 caller ext4_writepages+0x524/0xd24
   kworker/u16:8-9916  [000] ...1 22427.743932: jbd2_handle_start: dev 259,0 tid 56 type 2 line_no 2573 requested_blocks 8
   kworker/u16:8-9916  [000] ...1 22427.743936: ext4_da_write_pages: dev 259,0 ino 13 first_page 1 nr_to_write 1023 sync_mode 0
   kworker/u16:8-9916  [000] ...1 22427.743942: jbd2_handle_stats: dev 259,0 tid 56 type 2 line_no 2573 interval 0 sync 0 requested_blocks 8 dirtied_blocks 0
   kworker/u16:8-9916  [000] ...1 22427.743950: ext4_writepages_result: dev 259,0 ino 13 ret 0 pages_written 1 pages_skipped 0 sync_mode 0 writeback_index 1
    jbd2/sda16-8-578   [000] ...1 22429.041544: jbd2_start_commit: dev 259,0 transaction 56 sync 0
    jbd2/sda16-8-578   [000] ...2 22429.041737: jbd2_commit_locking: dev 259,0 transaction 56 sync 0
    jbd2/sda16-8-578   [000] ...2 22429.041783: jbd2_commit_flushing: dev 259,0 transaction 56 sync 0
    jbd2/sda16-8-578   [000] ...1 22429.041813: jbd2_commit_logging: dev 259,0 transaction 56 sync 0
    jbd2/sda16-8-578   [000] ...1 22429.041848: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 231
    jbd2/sda16-8-578   [000] ...1 22429.041861: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-578   [000] ...1 22429.041878: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 231 len 1 flags
    jbd2/sda16-8-578   [000] ...1 22429.041904: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-578   [000] ...1 22429.041924: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 231 pblk 754 len 1 mflags M ret 1
    jbd2/sda16-8-578   [000] ...1 22429.041938: ext4_es_insert_extent: dev 259,0 ino 8 es [231/1) mapped 754 status W
    jbd2/sda16-8-578   [000] ...1 22429.042145: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 232
    jbd2/sda16-8-578   [000] ...1 22429.042150: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-578   [000] ...1 22429.042155: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 232 len 1 flags
    jbd2/sda16-8-578   [000] ...1 22429.042160: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-578   [000] ...1 22429.042166: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 232 pblk 755 len 1 mflags M ret 1
    jbd2/sda16-8-578   [000] ...1 22429.042171: ext4_es_insert_extent: dev 259,0 ino 8 es [232/1) mapped 755 status W
    jbd2/sda16-8-578   [000] ...1 22429.042210: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 233
    jbd2/sda16-8-578   [000] ...1 22429.042214: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-578   [000] ...1 22429.042218: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 233 len 1 flags
    jbd2/sda16-8-578   [000] ...1 22429.042223: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-578   [000] ...1 22429.042227: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 233 pblk 756 len 1 mflags M ret 1
    jbd2/sda16-8-578   [000] ...1 22429.042232: ext4_es_insert_extent: dev 259,0 ino 8 es [233/1) mapped 756 status W
    jbd2/sda16-8-578   [000] ...1 22429.042248: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 234
    jbd2/sda16-8-578   [000] ...1 22429.042253: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-578   [000] ...1 22429.042257: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 234 len 1 flags
    jbd2/sda16-8-578   [000] ...1 22429.042262: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-578   [000] ...1 22429.042267: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 234 pblk 757 len 1 mflags M ret 1
    jbd2/sda16-8-578   [000] ...1 22429.042271: ext4_es_insert_extent: dev 259,0 ino 8 es [234/1) mapped 757 status W
    jbd2/sda16-8-578   [000] ...1 22429.042290: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 235
    jbd2/sda16-8-578   [000] ...1 22429.042294: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-578   [000] ...1 22429.042298: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 235 len 1 flags
    jbd2/sda16-8-578   [000] ...1 22429.042303: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-578   [000] ...1 22429.042307: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 235 pblk 758 len 1 mflags M ret 1
    jbd2/sda16-8-578   [000] ...1 22429.042311: ext4_es_insert_extent: dev 259,0 ino 8 es [235/1) mapped 758 status W
    jbd2/sda16-8-578   [000] ...1 22429.042329: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 236
    jbd2/sda16-8-578   [000] ...1 22429.042334: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-578   [000] ...1 22429.042338: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 236 len 1 flags
    jbd2/sda16-8-578   [000] ...1 22429.042352: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-578   [000] ...1 22429.042357: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 236 pblk 759 len 1 mflags M ret 1
    jbd2/sda16-8-578   [000] ...1 22429.042361: ext4_es_insert_extent: dev 259,0 ino 8 es [236/1) mapped 759 status W
    jbd2/sda16-8-578   [000] ...1 22429.057444: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 237
    jbd2/sda16-8-578   [000] ...1 22429.057531: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-578   [000] ...1 22429.057542: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 237 len 1 flags
    jbd2/sda16-8-578   [000] ...1 22429.057550: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-578   [000] ...1 22429.057556: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 237 pblk 760 len 1 mflags M ret 1
    jbd2/sda16-8-578   [000] ...1 22429.057562: ext4_es_insert_extent: dev 259,0 ino 8 es [237/1) mapped 760 status W
    jbd2/sda16-8-578   [000] ...2 22429.058924: jbd2_run_stats: dev 259,0 tid 56 wait 0 request_delay 0 running 5600 locked 0 flushing 0 logging 20 handle_count 4 blocks 5 blocks_logged 6
    jbd2/sda16-8-578   [000] ...1 22429.058999: jbd2_end_commit: dev 259,0 transaction 56 sync 0 head 25
```

## open-write-O_SYNC - barrier

```
  test-open-writ-10076 [000] ...1 23353.359860: ext4_request_inode: dev 259,0 dir 2 mode 0100360
  test-open-writ-10076 [000] ...1 23353.360035: ext4_journal_start: dev 259,0 blocks, 35 rsv_blocks, 0 caller __ext4_new_inode+0x750/0x1338
  test-open-writ-10076 [000] ...1 23353.360054: jbd2_handle_start: dev 259,0 tid 57 type 4 line_no 2460 requested_blocks 35
  test-open-writ-10076 [000] ...1 23353.360149: ext4_mark_inode_dirty: dev 259,0 ino 14 caller ext4_ext_tree_init+0x24/0x30
  test-open-writ-10076 [000] ...1 23353.360152: ext4_mark_inode_dirty: dev 259,0 ino 14 caller __ext4_new_inode+0x1108/0x1338
  test-open-writ-10076 [000] ...1 23353.360156: ext4_allocate_inode: dev 259,0 ino 14 dir 2 mode 0100360
  test-open-writ-10076 [000] ...1 23353.360168: ext4_es_lookup_extent_enter: dev 259,0 ino 2 lblk 0
  test-open-writ-10076 [000] ...1 23353.360172: ext4_es_lookup_extent_exit: dev 259,0 ino 2 found 1 [0/1) 1549 W0x10
  test-open-writ-10076 [000] ...1 23353.360190: ext4_mark_inode_dirty: dev 259,0 ino 2 caller add_dirent_to_buf+0x170/0x1dc
  test-open-writ-10076 [000] ...1 23353.360200: ext4_mark_inode_dirty: dev 259,0 ino 14 caller ext4_add_nondir+0x34/0x7c
  test-open-writ-10076 [000] ...1 23353.360213: jbd2_handle_stats: dev 259,0 tid 57 type 4 line_no 2460 interval 0 sync 0 requested_blocks 35 dirtied_blocks 4
  test-open-writ-10076 [000] ...1 23353.360261: ext4_da_write_begin: dev 259,0 ino 14 pos 0 len 12 flags 0
  test-open-writ-10076 [000] ...1 23353.360276: ext4_journal_start: dev 259,0 blocks, 1 rsv_blocks, 0 caller ext4_da_write_begin+0x1d4/0x304
  test-open-writ-10076 [000] ...1 23353.360278: jbd2_handle_start: dev 259,0 tid 57 type 2 line_no 2765 requested_blocks 1
  test-open-writ-10076 [000] ...1 23353.360286: ext4_es_lookup_extent_enter: dev 259,0 ino 14 lblk 0
  test-open-writ-10076 [000] ...1 23353.360287: ext4_es_lookup_extent_exit: dev 259,0 ino 14 found 0 [0/0) 0
  test-open-writ-10076 [000] ...1 23353.360291: ext4_ext_map_blocks_enter: dev 259,0 ino 14 lblk 0 len 1 flags
  test-open-writ-10076 [000] ...1 23353.360298: ext4_es_find_delayed_extent_range_enter: dev 259,0 ino 14 lblk 0
  test-open-writ-10076 [000] ...1 23353.360303: ext4_es_find_delayed_extent_range_exit: dev 259,0 ino 14 es [0/0) mapped 0 status
  test-open-writ-10076 [000] ...1 23353.360306: ext4_es_insert_extent: dev 259,0 ino 14 es [0/4294967295) mapped 576460752303423487 status H
  test-open-writ-10076 [000] ...1 23353.360316: ext4_ext_map_blocks_exit: dev 259,0 ino 14 flags  lblk 0 pblk 18446743804945496784 len 1 mflags  ret 0
  test-open-writ-10076 [000] ...2 23353.360322: ext4_da_reserve_space: dev 259,0 ino 14 mode 0100360 i_blocks 0 reserved_data_blocks 1 reserved_meta_blocks 0
  test-open-writ-10076 [000] ...1 23353.360323: ext4_es_insert_extent: dev 259,0 ino 14 es [0/1) mapped 576460752303423487 status D
  test-open-writ-10076 [000] ...1 23353.360337: ext4_da_write_end: dev 259,0 ino 14 pos 0 len 12 copied 12
  test-open-writ-10076 [000] ...1 23353.360353: ext4_journal_start: dev 259,0 blocks, 2 rsv_blocks, 0 caller ext4_dirty_inode+0x30/0x68
  test-open-writ-10076 [000] ...1 23353.360354: ext4_mark_inode_dirty: dev 259,0 ino 14 caller ext4_dirty_inode+0x44/0x68
  test-open-writ-10076 [000] ...1 23353.360356: jbd2_handle_stats: dev 259,0 tid 57 type 2 line_no 2765 interval 0 sync 0 requested_blocks 1 dirtied_blocks 0
  test-open-writ-10076 [000] ...1 23353.360366: ext4_sync_file_enter: dev 259,0 ino 14 parent 2 datasync 0
  test-open-writ-10076 [000] ...1 23353.360370: ext4_writepages: dev 259,0 ino 14 nr_to_write 9223372036854775807 pages_skipped 0 range_start 0 range_end 11 sync_mode 1 for_kupdate 0 range_cyclic 0 writeback_index 0
  test-open-writ-10076 [000] ...1 23353.360382: ext4_journal_start: dev 259,0 blocks, 8 rsv_blocks, 0 caller ext4_writepages+0x524/0xd24
  test-open-writ-10076 [000] ...1 23353.360383: jbd2_handle_start: dev 259,0 tid 57 type 2 line_no 2573 requested_blocks 8
  test-open-writ-10076 [000] ...1 23353.360388: ext4_da_write_pages: dev 259,0 ino 14 first_page 0 nr_to_write 9223372036854775807 sync_mode 1
  test-open-writ-10076 [000] ...1 23353.360401: ext4_da_write_pages_extent: dev 259,0 ino 14 lblk 0 len 1 flags 0x200
  test-open-writ-10076 [000] ...1 23353.360403: ext4_es_lookup_extent_enter: dev 259,0 ino 14 lblk 0
  test-open-writ-10076 [000] ...1 23353.360404: ext4_es_lookup_extent_exit: dev 259,0 ino 14 found 1 [0/1) 576460752303423487 D0x10
  test-open-writ-10076 [000] ...1 23353.360405: ext4_ext_map_blocks_enter: dev 259,0 ino 14 lblk 0 len 1 flags CREATE|DELALLOC|METADATA_NOFAIL
  test-open-writ-10076 [000] ...1 23353.360415: ext4_request_blocks: dev 259,0 ino 14 flags HINT_DATA|DELALLOC_RESV|USE_RESV len 1 lblk 0 goal 0 lleft 0 lright 0 pleft 0 pright 0
  test-open-writ-10076 [000] ...1 23353.360448: ext4_mballoc_prealloc: dev 259,0 inode 14 orig 0/0/1@0 result 0/2052/1@0
  test-open-writ-10076 [000] ...1 23353.360451: ext4_allocate_blocks: dev 259,0 ino 14 flags HINT_DATA|DELALLOC_RESV|USE_RESV len 1 block 2052 lblk 0 goal 0 lleft 0 lright 0 pleft 0 pright 0
  test-open-writ-10076 [000] ...1 23353.360461: ext4_mark_inode_dirty: dev 259,0 ino 14 caller __ext4_ext_dirty+0x6c/0x78
  test-open-writ-10076 [000] ...1 23353.360466: ext4_get_reserved_cluster_alloc: dev 259,0 ino 14 lblk 0 len 1
  test-open-writ-10076 [000] ...2 23353.360470: ext4_da_update_reserve_space: dev 259,0 ino 14 mode 0100360 i_blocks 0 used_blocks 1 reserved_data_blocks 1 reserved_meta_blocks 0 allocated_meta_blocks 0 quota_claim 1
  test-open-writ-10076 [000] ...1 23353.360472: ext4_journal_start: dev 259,0 blocks, 2 rsv_blocks, 0 caller ext4_dirty_inode+0x30/0x68
  test-open-writ-10076 [000] ...1 23353.360473: ext4_mark_inode_dirty: dev 259,0 ino 14 caller ext4_dirty_inode+0x44/0x68
  test-open-writ-10076 [000] ...1 23353.360475: ext4_ext_map_blocks_exit: dev 259,0 ino 14 flags CREATE|DELALLOC|METADATA_NOFAIL lblk 0 pblk 2052 len 1 mflags NM ret 1
  test-open-writ-10076 [000] ...1 23353.360477: ext4_es_insert_extent: dev 259,0 ino 14 es [0/1) mapped 2052 status W
  test-open-writ-10076 [000] ...1 23353.360506: ext4_mark_inode_dirty: dev 259,0 ino 14 caller ext4_writepages+0xc1c/0xd24
  test-open-writ-10076 [000] ...1 23353.360508: jbd2_handle_stats: dev 259,0 tid 57 type 2 line_no 2573 interval 0 sync 0 requested_blocks 8 dirtied_blocks 1
  test-open-writ-10076 [000] .n.1 23353.360648: ext4_writepages_result: dev 259,0 ino 14 ret 0 pages_written 1 pages_skipped 0 sync_mode 1 writeback_index 0
    jbd2/sda16-8-578   [001] ...1 23353.380478: jbd2_start_commit: dev 259,0 transaction 57 sync 0
    jbd2/sda16-8-578   [001] ...2 23353.380541: jbd2_commit_locking: dev 259,0 transaction 57 sync 0
    jbd2/sda16-8-578   [001] ...3 23353.380556: jbd2_checkpoint_stats: dev 259,0 tid 55 chp_time 0 forced_to_close 0 written 0 dropped 5
    jbd2/sda16-8-578   [001] ...3 23353.380563: jbd2_drop_transaction: dev 259,0 transaction 55 sync 0
    jbd2/sda16-8-578   [001] ...2 23353.380578: jbd2_commit_flushing: dev 259,0 transaction 57 sync 0
    jbd2/sda16-8-578   [001] ...1 23353.380586: jbd2_commit_logging: dev 259,0 transaction 57 sync 0
    jbd2/sda16-8-578   [001] ...1 23353.380601: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 238
    jbd2/sda16-8-578   [001] ...1 23353.380607: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-578   [001] ...1 23353.380612: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 238 len 1 flags
    jbd2/sda16-8-578   [001] ...1 23353.380620: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-578   [001] ...1 23353.380624: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 238 pblk 761 len 1 mflags M ret 1
    jbd2/sda16-8-578   [001] ...1 23353.380630: ext4_es_insert_extent: dev 259,0 ino 8 es [238/1) mapped 761 status W
    jbd2/sda16-8-578   [001] ...1 23353.380706: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 239
    jbd2/sda16-8-578   [001] ...1 23353.380707: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-578   [001] ...1 23353.380708: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 239 len 1 flags
    jbd2/sda16-8-578   [001] ...1 23353.380709: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-578   [001] ...1 23353.380713: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 239 pblk 762 len 1 mflags M ret 1
    jbd2/sda16-8-578   [001] ...1 23353.380714: ext4_es_insert_extent: dev 259,0 ino 8 es [239/1) mapped 762 status W
    jbd2/sda16-8-578   [001] ...1 23353.380727: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 240
    jbd2/sda16-8-578   [001] ...1 23353.380729: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-578   [001] ...1 23353.380730: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 240 len 1 flags
    jbd2/sda16-8-578   [001] ...1 23353.380730: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-578   [001] ...1 23353.380731: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 240 pblk 763 len 1 mflags M ret 1
    jbd2/sda16-8-578   [001] ...1 23353.380732: ext4_es_insert_extent: dev 259,0 ino 8 es [240/1) mapped 763 status W
    jbd2/sda16-8-578   [001] ...1 23353.380737: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 241
    jbd2/sda16-8-578   [001] ...1 23353.380738: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-578   [001] ...1 23353.380739: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 241 len 1 flags
    jbd2/sda16-8-578   [001] ...1 23353.380740: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-578   [001] ...1 23353.380741: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 241 pblk 764 len 1 mflags M ret 1
    jbd2/sda16-8-578   [001] ...1 23353.380741: ext4_es_insert_extent: dev 259,0 ino 8 es [241/1) mapped 764 status W
    jbd2/sda16-8-578   [001] ...1 23353.380746: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 242
    jbd2/sda16-8-578   [001] ...1 23353.380747: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-578   [001] ...1 23353.380748: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 242 len 1 flags
    jbd2/sda16-8-578   [001] ...1 23353.380749: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-578   [001] ...1 23353.380750: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 242 pblk 765 len 1 mflags M ret 1
    jbd2/sda16-8-578   [001] ...1 23353.380751: ext4_es_insert_extent: dev 259,0 ino 8 es [242/1) mapped 765 status W
    jbd2/sda16-8-578   [001] ...1 23353.380755: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 243
    jbd2/sda16-8-578   [001] ...1 23353.380756: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-578   [001] ...1 23353.380757: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 243 len 1 flags
    jbd2/sda16-8-578   [001] ...1 23353.380758: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-578   [001] ...1 23353.380759: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 243 pblk 766 len 1 mflags M ret 1
    jbd2/sda16-8-578   [001] ...1 23353.380760: ext4_es_insert_extent: dev 259,0 ino 8 es [243/1) mapped 766 status W
    jbd2/sda16-8-578   [001] ...1 23353.381154: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 244
    jbd2/sda16-8-578   [001] ...1 23353.381158: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-578   [001] ...1 23353.381176: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 244 len 1 flags
    jbd2/sda16-8-578   [001] ...1 23353.381177: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-578   [001] ...1 23353.381178: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 244 pblk 767 len 1 mflags M ret 1
    jbd2/sda16-8-578   [001] ...1 23353.381179: ext4_es_insert_extent: dev 259,0 ino 8 es [244/1) mapped 767 status W
    jbd2/sda16-8-578   [001] ...3 23353.382104: jbd2_checkpoint_stats: dev 259,0 tid 56 chp_time 0 forced_to_close 0 written 0 dropped 5
    jbd2/sda16-8-578   [001] ...3 23353.382129: jbd2_drop_transaction: dev 259,0 transaction 56 sync 0
    jbd2/sda16-8-578   [001] ...2 23353.382136: jbd2_run_stats: dev 259,0 tid 57 wait 0 request_delay 0 running 20 locked 0 flushing 0 logging 0 handle_count 3 blocks 5 blocks_logged 6
    jbd2/sda16-8-578   [001] ...1 23353.382140: jbd2_end_commit: dev 259,0 transaction 57 sync 0 head 25
  test-open-writ-10076 [000] ...1 23353.382247: ext4_sync_file_exit: dev 259,0 ino 14 ret 0
  test-open-writ-10076 [000] ...1 23353.382855: ext4_discard_preallocations: dev 259,0 ino 14
   kworker/u16:8-9916  [001] ...1 23357.975610: ext4_writepages: dev 259,0 ino 14 nr_to_write 1024 pages_skipped 0 range_start 0 range_end 9223372036854775807 sync_mode 0 for_kupdate 1 range_cyclic 1 writeback_index 0
   kworker/u16:8-9916  [001] ...1 23357.975616: ext4_writepages_result: dev 259,0 ino 14 ret 0 pages_written 0 pages_skipped 0 sync_mode 0 writeback_index 0
```

## open-write-fsync - barrier

```
  test-open-writ-10096 [000] ...1 23439.421309: ext4_request_inode: dev 259,0 dir 2 mode 0107220
  test-open-writ-10096 [000] ...1 23439.421469: ext4_journal_start: dev 259,0 blocks, 35 rsv_blocks, 0 caller __ext4_new_inode+0x750/0x1338
  test-open-writ-10096 [000] ...1 23439.421501: jbd2_handle_start: dev 259,0 tid 58 type 4 line_no 2460 requested_blocks 35
  test-open-writ-10096 [000] ...1 23439.421664: ext4_mark_inode_dirty: dev 259,0 ino 16 caller ext4_ext_tree_init+0x24/0x30
  test-open-writ-10096 [000] ...1 23439.421668: ext4_mark_inode_dirty: dev 259,0 ino 16 caller __ext4_new_inode+0x1108/0x1338
  test-open-writ-10096 [000] ...1 23439.421674: ext4_allocate_inode: dev 259,0 ino 16 dir 2 mode 0107220
  test-open-writ-10096 [000] ...1 23439.421693: ext4_es_lookup_extent_enter: dev 259,0 ino 2 lblk 0
  test-open-writ-10096 [000] ...1 23439.421700: ext4_es_lookup_extent_exit: dev 259,0 ino 2 found 1 [0/1) 1549 W0x10
  test-open-writ-10096 [000] ...1 23439.421732: ext4_mark_inode_dirty: dev 259,0 ino 2 caller add_dirent_to_buf+0x170/0x1dc
  test-open-writ-10096 [000] ...1 23439.421745: ext4_mark_inode_dirty: dev 259,0 ino 16 caller ext4_add_nondir+0x34/0x7c
  test-open-writ-10096 [000] ...1 23439.421769: jbd2_handle_stats: dev 259,0 tid 58 type 4 line_no 2460 interval 0 sync 0 requested_blocks 35 dirtied_blocks 4
  test-open-writ-10096 [000] ...1 23439.421849: ext4_da_write_begin: dev 259,0 ino 16 pos 0 len 12 flags 0
  test-open-writ-10096 [000] ...1 23439.421872: ext4_journal_start: dev 259,0 blocks, 1 rsv_blocks, 0 caller ext4_da_write_begin+0x1d4/0x304
  test-open-writ-10096 [000] ...1 23439.421875: jbd2_handle_start: dev 259,0 tid 58 type 2 line_no 2765 requested_blocks 1
  test-open-writ-10096 [000] ...1 23439.421890: ext4_es_lookup_extent_enter: dev 259,0 ino 16 lblk 0
  test-open-writ-10096 [000] ...1 23439.421890: ext4_es_lookup_extent_exit: dev 259,0 ino 16 found 0 [0/0) 0
  test-open-writ-10096 [000] ...1 23439.421900: ext4_ext_map_blocks_enter: dev 259,0 ino 16 lblk 0 len 1 flags
  test-open-writ-10096 [000] ...1 23439.421912: ext4_es_find_delayed_extent_range_enter: dev 259,0 ino 16 lblk 0
  test-open-writ-10096 [000] ...1 23439.421919: ext4_es_find_delayed_extent_range_exit: dev 259,0 ino 16 es [0/0) mapped 0 status
  test-open-writ-10096 [000] ...1 23439.421928: ext4_es_insert_extent: dev 259,0 ino 16 es [0/4294967295) mapped 576460752303423487 status H
  test-open-writ-10096 [000] ...1 23439.421950: ext4_ext_map_blocks_exit: dev 259,0 ino 16 flags  lblk 0 pblk 18446743803717991120 len 1 mflags  ret 0
  test-open-writ-10096 [000] ...2 23439.421960: ext4_da_reserve_space: dev 259,0 ino 16 mode 0107220 i_blocks 0 reserved_data_blocks 1 reserved_meta_blocks 0
  test-open-writ-10096 [000] ...1 23439.421962: ext4_es_insert_extent: dev 259,0 ino 16 es [0/1) mapped 576460752303423487 status D
  test-open-writ-10096 [000] ...1 23439.421988: ext4_da_write_end: dev 259,0 ino 16 pos 0 len 12 copied 12
  test-open-writ-10096 [000] ...1 23439.422023: ext4_journal_start: dev 259,0 blocks, 2 rsv_blocks, 0 caller ext4_dirty_inode+0x30/0x68
  test-open-writ-10096 [000] ...1 23439.422024: ext4_mark_inode_dirty: dev 259,0 ino 16 caller ext4_dirty_inode+0x44/0x68
  test-open-writ-10096 [000] ...1 23439.422027: jbd2_handle_stats: dev 259,0 tid 58 type 2 line_no 2765 interval 0 sync 0 requested_blocks 1 dirtied_blocks 0
  test-open-writ-10096 [000] ...1 23439.422049: ext4_sync_file_enter: dev 259,0 ino 16 parent 2 datasync 0
  test-open-writ-10096 [000] ...1 23439.422058: ext4_writepages: dev 259,0 ino 16 nr_to_write 9223372036854775807 pages_skipped 0 range_start 0 range_end 9223372036854775807 sync_mode 1 for_kupdate 0 range_cyclic 0 writeback_index 0
  test-open-writ-10096 [000] ...1 23439.422080: ext4_journal_start: dev 259,0 blocks, 8 rsv_blocks, 0 caller ext4_writepages+0x524/0xd24
  test-open-writ-10096 [000] ...1 23439.422081: jbd2_handle_start: dev 259,0 tid 58 type 2 line_no 2573 requested_blocks 8
  test-open-writ-10096 [000] ...1 23439.422087: ext4_da_write_pages: dev 259,0 ino 16 first_page 0 nr_to_write 9223372036854775807 sync_mode 1
  test-open-writ-10096 [000] ...1 23439.422107: ext4_da_write_pages_extent: dev 259,0 ino 16 lblk 0 len 1 flags 0x200
  test-open-writ-10096 [000] ...1 23439.422108: ext4_es_lookup_extent_enter: dev 259,0 ino 16 lblk 0
  test-open-writ-10096 [000] ...1 23439.422109: ext4_es_lookup_extent_exit: dev 259,0 ino 16 found 1 [0/1) 576460752303423487 D0x10
  test-open-writ-10096 [000] ...1 23439.422111: ext4_ext_map_blocks_enter: dev 259,0 ino 16 lblk 0 len 1 flags CREATE|DELALLOC|METADATA_NOFAIL
  test-open-writ-10096 [000] ...1 23439.422130: ext4_request_blocks: dev 259,0 ino 16 flags HINT_DATA|DELALLOC_RESV|USE_RESV len 1 lblk 0 goal 0 lleft 0 lright 0 pleft 0 pright 0
  test-open-writ-10096 [000] ...1 23439.422183: ext4_mballoc_prealloc: dev 259,0 inode 16 orig 0/0/1@0 result 0/2053/1@0
  test-open-writ-10096 [000] ...1 23439.422189: ext4_allocate_blocks: dev 259,0 ino 16 flags HINT_DATA|DELALLOC_RESV|USE_RESV len 1 block 2053 lblk 0 goal 0 lleft 0 lright 0 pleft 0 pright 0
  test-open-writ-10096 [000] ...1 23439.422205: ext4_mark_inode_dirty: dev 259,0 ino 16 caller __ext4_ext_dirty+0x6c/0x78
  test-open-writ-10096 [000] ...1 23439.422215: ext4_get_reserved_cluster_alloc: dev 259,0 ino 16 lblk 0 len 1
  test-open-writ-10096 [000] ...2 23439.422222: ext4_da_update_reserve_space: dev 259,0 ino 16 mode 0107220 i_blocks 0 used_blocks 1 reserved_data_blocks 1 reserved_meta_blocks 0 allocated_meta_blocks 0 quota_claim 1
  test-open-writ-10096 [000] ...1 23439.422225: ext4_journal_start: dev 259,0 blocks, 2 rsv_blocks, 0 caller ext4_dirty_inode+0x30/0x68
  test-open-writ-10096 [000] ...1 23439.422226: ext4_mark_inode_dirty: dev 259,0 ino 16 caller ext4_dirty_inode+0x44/0x68
  test-open-writ-10096 [000] ...1 23439.422229: ext4_ext_map_blocks_exit: dev 259,0 ino 16 flags CREATE|DELALLOC|METADATA_NOFAIL lblk 0 pblk 2053 len 1 mflags NM ret 1
  test-open-writ-10096 [000] ...1 23439.422232: ext4_es_insert_extent: dev 259,0 ino 16 es [0/1) mapped 2053 status W
  test-open-writ-10096 [000] ...1 23439.422281: ext4_mark_inode_dirty: dev 259,0 ino 16 caller ext4_writepages+0xc1c/0xd24
  test-open-writ-10096 [000] ...1 23439.422284: jbd2_handle_stats: dev 259,0 tid 58 type 2 line_no 2573 interval 0 sync 0 requested_blocks 8 dirtied_blocks 1
  test-open-writ-10096 [000] ...1 23439.422397: ext4_journal_start: dev 259,0 blocks, 8 rsv_blocks, 0 caller ext4_writepages+0x524/0xd24
  test-open-writ-10096 [000] ...1 23439.422398: jbd2_handle_start: dev 259,0 tid 58 type 2 line_no 2573 requested_blocks 8
  test-open-writ-10096 [000] ...1 23439.422399: ext4_da_write_pages: dev 259,0 ino 16 first_page 1 nr_to_write 9223372036854775806 sync_mode 1
  test-open-writ-10096 [000] ...1 23439.422400: jbd2_handle_stats: dev 259,0 tid 58 type 2 line_no 2573 interval 0 sync 0 requested_blocks 8 dirtied_blocks 0
  test-open-writ-10096 [000] .n.1 23439.422521: ext4_writepages_result: dev 259,0 ino 16 ret 0 pages_written 1 pages_skipped 0 sync_mode 1 writeback_index 1
    jbd2/sda16-8-578   [001] ...1 23439.436833: jbd2_start_commit: dev 259,0 transaction 58 sync 0
    jbd2/sda16-8-578   [001] ...2 23439.436860: jbd2_commit_locking: dev 259,0 transaction 58 sync 0
    jbd2/sda16-8-578   [001] ...2 23439.436870: jbd2_commit_flushing: dev 259,0 transaction 58 sync 0
    jbd2/sda16-8-578   [001] ...1 23439.436879: jbd2_commit_logging: dev 259,0 transaction 58 sync 0
    jbd2/sda16-8-578   [001] ...1 23439.436885: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 245
    jbd2/sda16-8-578   [001] ...1 23439.436888: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-578   [001] ...1 23439.436891: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 245 len 1 flags
    jbd2/sda16-8-578   [001] ...1 23439.436895: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-578   [001] ...1 23439.436897: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 245 pblk 768 len 1 mflags M ret 1
    jbd2/sda16-8-578   [001] ...1 23439.436899: ext4_es_insert_extent: dev 259,0 ino 8 es [245/1) mapped 768 status W
    jbd2/sda16-8-578   [001] ...1 23439.436931: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 246
    jbd2/sda16-8-578   [001] ...1 23439.436932: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-578   [001] ...1 23439.436932: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 246 len 1 flags
    jbd2/sda16-8-578   [001] ...1 23439.436933: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-578   [001] ...1 23439.436934: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 246 pblk 769 len 1 mflags M ret 1
    jbd2/sda16-8-578   [001] ...1 23439.436935: ext4_es_insert_extent: dev 259,0 ino 8 es [246/1) mapped 769 status W
    jbd2/sda16-8-578   [001] ...1 23439.436944: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 247
    jbd2/sda16-8-578   [001] ...1 23439.436944: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-578   [001] ...1 23439.436946: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 247 len 1 flags
    jbd2/sda16-8-578   [001] ...1 23439.436947: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-578   [001] ...1 23439.436947: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 247 pblk 770 len 1 mflags M ret 1
    jbd2/sda16-8-578   [001] ...1 23439.436948: ext4_es_insert_extent: dev 259,0 ino 8 es [247/1) mapped 770 status W
    jbd2/sda16-8-578   [001] ...1 23439.436950: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 248
    jbd2/sda16-8-578   [001] ...1 23439.436951: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-578   [001] ...1 23439.436952: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 248 len 1 flags
    jbd2/sda16-8-578   [001] ...1 23439.436953: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-578   [001] ...1 23439.436953: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 248 pblk 771 len 1 mflags M ret 1
    jbd2/sda16-8-578   [001] ...1 23439.436954: ext4_es_insert_extent: dev 259,0 ino 8 es [248/1) mapped 771 status W
    jbd2/sda16-8-578   [001] ...1 23439.436957: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 249
    jbd2/sda16-8-578   [001] ...1 23439.436958: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-578   [001] ...1 23439.436958: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 249 len 1 flags
    jbd2/sda16-8-578   [001] ...1 23439.436959: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-578   [001] ...1 23439.436960: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 249 pblk 772 len 1 mflags M ret 1
    jbd2/sda16-8-578   [001] ...1 23439.436961: ext4_es_insert_extent: dev 259,0 ino 8 es [249/1) mapped 772 status W
    jbd2/sda16-8-578   [001] ...1 23439.436964: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 250
    jbd2/sda16-8-578   [001] ...1 23439.436966: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-578   [001] ...1 23439.436966: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 250 len 1 flags
    jbd2/sda16-8-578   [001] ...1 23439.436967: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-578   [001] ...1 23439.436968: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 250 pblk 773 len 1 mflags M ret 1
    jbd2/sda16-8-578   [001] ...1 23439.436969: ext4_es_insert_extent: dev 259,0 ino 8 es [250/1) mapped 773 status W
    jbd2/sda16-8-578   [001] ...1 23439.437252: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 251
    jbd2/sda16-8-578   [001] ...1 23439.437268: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-578   [001] ...1 23439.437269: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 251 len 1 flags
    jbd2/sda16-8-578   [001] ...1 23439.437270: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-578   [001] ...1 23439.437271: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 251 pblk 774 len 1 mflags M ret 1
    jbd2/sda16-8-578   [001] ...1 23439.437272: ext4_es_insert_extent: dev 259,0 ino 8 es [251/1) mapped 774 status W
    jbd2/sda16-8-578   [002] ...3 23439.438308: jbd2_checkpoint_stats: dev 259,0 tid 57 chp_time 0 forced_to_close 0 written 0 dropped 5
    jbd2/sda16-8-578   [002] ...3 23439.438350: jbd2_drop_transaction: dev 259,0 transaction 57 sync 0
    jbd2/sda16-8-578   [002] ...2 23439.438355: jbd2_run_stats: dev 259,0 tid 58 wait 0 request_delay 0 running 10 locked 0 flushing 0 logging 10 handle_count 4 blocks 5 blocks_logged 6
    jbd2/sda16-8-578   [002] ...1 23439.438361: jbd2_end_commit: dev 259,0 transaction 58 sync 0 head 25
  test-open-writ-10096 [000] ...1 23439.438391: ext4_sync_file_exit: dev 259,0 ino 16 ret 0
  test-open-writ-10096 [000] ...1 23439.439851: ext4_discard_preallocations: dev 259,0 ino 16
   kworker/u16:9-9917  [000] ...1 23444.432269: ext4_writepages: dev 259,0 ino 16 nr_to_write 1024 pages_skipped 0 range_start 0 range_end 9223372036854775807 sync_mode 0 for_kupdate 1 range_cyclic 1 writeback_index 1
   kworker/u16:9-9917  [000] ...1 23444.432444: ext4_writepages_result: dev 259,0 ino 16 ret 0 pages_written 0 pages_skipped 0 sync_mode 0 writeback_index 1
```
