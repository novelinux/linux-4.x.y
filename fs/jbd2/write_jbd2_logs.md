# JBD2 LOGS

```#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include <fcntl.h>
#include <unistd.h>

int main(int argc, char *argv[])
{
    char *filename = argv[1];

    int fd = open(filename, O_CREAT);
    if (fd < 0) {
        printf("open %s failed: %s\n", filename, strerror(errno));
        return 1;
    }
    write(fd, "hello world\n", 12);
    //fsync(fd);

    return 0;
}
```

## JBD2 - barrier

```
            test-5932  [000] ...1  1167.298416: jbd2_handle_start: dev 259,0 tid 33 type 4 line_no 2460 requested_blocks 35
            test-5932  [000] ...1  1167.298922: jbd2_handle_stats: dev 259,0 tid 33 type 4 line_no 2460 interval 0 sync 0 requested_blocks 35 dirtied_blocks 4
    jbd2/sda16-8-578   [000] ...1  1173.041427: jbd2_start_commit: dev 259,0 transaction 33 sync 0
    jbd2/sda16-8-578   [000] ...2  1173.041618: jbd2_commit_locking: dev 259,0 transaction 33 sync 0
    jbd2/sda16-8-578   [000] ...3  1173.041677: jbd2_checkpoint_stats: dev 259,0 tid 30 chp_time 0 forced_to_close 0 written 0 dropped 5
    jbd2/sda16-8-578   [000] ...3  1173.041689: jbd2_drop_transaction: dev 259,0 transaction 30 sync 0
    jbd2/sda16-8-578   [000] ...2  1173.041739: jbd2_commit_flushing: dev 259,0 transaction 33 sync 0
    jbd2/sda16-8-578   [000] ...1  1173.041772: jbd2_commit_logging: dev 259,0 transaction 33 sync 0
    jbd2/sda16-8-578   [000] ...2  1173.069914: jbd2_run_stats: dev 259,0 tid 33 wait 0 request_delay 0 running 5740 locked 0 flushing 0 logging 30 handle_count 1 blocks 4 blocks_logged 5
    jbd2/sda16-8-578   [000] ...1  1173.070054: jbd2_end_commit: dev 259,0 transaction 33 sync 0 head 25
```

## Normal - barrier

```
            test-5911  [000] ...1  1066.744935: ext4_request_inode: dev 259,0 dir 2 mode 0105160
            test-5911  [000] ...1  1066.745105: ext4_journal_start: dev 259,0 blocks, 35 rsv_blocks, 0 caller __ext4_new_inode+0x750/0x1338
            test-5911  [000] ...1  1066.745143: jbd2_handle_start: dev 259,0 tid 31 type 4 line_no 2460 requested_blocks 35
            test-5911  [000] ...1  1066.745301: ext4_mark_inode_dirty: dev 259,0 ino 13 caller ext4_ext_tree_init+0x24/0x30
            test-5911  [000] ...1  1066.745305: ext4_mark_inode_dirty: dev 259,0 ino 13 caller __ext4_new_inode+0x1108/0x1338
            test-5911  [000] ...1  1066.745310: ext4_allocate_inode: dev 259,0 ino 13 dir 2 mode 0105160
            test-5911  [000] ...1  1066.745330: ext4_es_lookup_extent_enter: dev 259,0 ino 2 lblk 0
            test-5911  [000] ...1  1066.745337: ext4_es_lookup_extent_exit: dev 259,0 ino 2 found 1 [0/1) 1549 W0x10
            test-5911  [000] ...1  1066.745366: ext4_mark_inode_dirty: dev 259,0 ino 2 caller add_dirent_to_buf+0x170/0x1dc
            test-5911  [000] ...1  1066.745376: ext4_mark_inode_dirty: dev 259,0 ino 13 caller ext4_add_nondir+0x34/0x7c
            test-5911  [000] ...1  1066.745398: jbd2_handle_stats: dev 259,0 tid 31 type 4 line_no 2460 interval 0 sync 0 requested_blocks 35 dirtied_blocks 4
    jbd2/sda16-8-578   [000] ...1  1072.038350: jbd2_start_commit: dev 259,0 transaction 31 sync 0
    jbd2/sda16-8-578   [000] ...2  1072.038495: jbd2_commit_locking: dev 259,0 transaction 31 sync 0
    jbd2/sda16-8-578   [000] ...2  1072.038544: jbd2_commit_flushing: dev 259,0 transaction 31 sync 0
    jbd2/sda16-8-578   [000] ...1  1072.038575: jbd2_commit_logging: dev 259,0 transaction 31 sync 0
    jbd2/sda16-8-578   [000] ...1  1072.038606: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 44
    jbd2/sda16-8-578   [000] .n.1  1072.038699: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-578   [000] ...1  1072.039037: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 44 len 1 flags
    jbd2/sda16-8-578   [000] ...1  1072.039069: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-578   [000] ...1  1072.039083: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 44 pblk 567 len 1 mflags M ret 1
    jbd2/sda16-8-578   [000] ...1  1072.039096: ext4_es_insert_extent: dev 259,0 ino 8 es [44/1) mapped 567 status W
    jbd2/sda16-8-578   [000] ...1  1072.039279: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 45
    jbd2/sda16-8-578   [000] ...1  1072.039285: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-578   [000] ...1  1072.039290: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 45 len 1 flags
    jbd2/sda16-8-578   [000] ...1  1072.039296: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-578   [000] ...1  1072.039301: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 45 pblk 568 len 1 mflags M ret 1
    jbd2/sda16-8-578   [000] ...1  1072.039305: ext4_es_insert_extent: dev 259,0 ino 8 es [45/1) mapped 568 status W
    jbd2/sda16-8-578   [000] ...1  1072.039342: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 46
    jbd2/sda16-8-578   [000] ...1  1072.039346: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-578   [000] ...1  1072.039351: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 46 len 1 flags
    jbd2/sda16-8-578   [000] ...1  1072.039357: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-578   [000] ...1  1072.039362: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 46 pblk 569 len 1 mflags M ret 1
    jbd2/sda16-8-578   [000] ...1  1072.039366: ext4_es_insert_extent: dev 259,0 ino 8 es [46/1) mapped 569 status W
    jbd2/sda16-8-578   [000] ...1  1072.039382: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 47
    jbd2/sda16-8-578   [000] ...1  1072.039387: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-578   [000] ...1  1072.039392: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 47 len 1 flags
    jbd2/sda16-8-578   [000] ...1  1072.039396: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-578   [000] ...1  1072.039401: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 47 pblk 570 len 1 mflags M ret 1
    jbd2/sda16-8-578   [000] ...1  1072.039405: ext4_es_insert_extent: dev 259,0 ino 8 es [47/1) mapped 570 status W
    jbd2/sda16-8-578   [000] ...1  1072.039422: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 48
    jbd2/sda16-8-578   [000] ...1  1072.039427: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-578   [000] ...1  1072.039438: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 48 len 1 flags
    jbd2/sda16-8-578   [000] ...1  1072.039445: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-578   [000] ...1  1072.039449: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 48 pblk 571 len 1 mflags M ret 1
    jbd2/sda16-8-578   [000] ...1  1072.039453: ext4_es_insert_extent: dev 259,0 ino 8 es [48/1) mapped 571 status W
    jbd2/sda16-8-578   [000] ...1  1072.058063: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 49
    jbd2/sda16-8-578   [000] ...1  1072.058172: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-578   [000] ...1  1072.058187: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 49 len 1 flags
    jbd2/sda16-8-578   [000] ...1  1072.058199: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-578   [000] ...1  1072.058222: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 49 pblk 572 len 1 mflags M ret 1
    jbd2/sda16-8-578   [000] ...1  1072.058232: ext4_es_insert_extent: dev 259,0 ino 8 es [49/1) mapped 572 status W
    jbd2/sda16-8-578   [000] ...2  1072.059925: jbd2_run_stats: dev 259,0 tid 31 wait 0 request_delay 0 running 5300 locked 0 flushing 0 logging 20 handle_count 1 blocks 4 blocks_logged 5
    jbd2/sda16-8-578   [000] ...1  1072.059961: jbd2_end_commit: dev 259,0 transaction 31 sync 0 head 25
```


## O_SYNC - nobarrier

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
            test-5994  [000] ...1  1528.222914: ext4_request_inode: dev 259,0 dir 2 mode 0102620
            test-5994  [000] ...1  1528.223076: ext4_journal_start: dev 259,0 blocks, 35 rsv_blocks, 0 caller __ext4_new_inode+0x750/0x1338
            test-5994  [000] ...1  1528.223115: jbd2_handle_start: dev 259,0 tid 36 type 4 line_no 2460 requested_blocks 35
            test-5994  [000] ...1  1528.223283: ext4_mark_inode_dirty: dev 259,0 ino 13 caller ext4_ext_tree_init+0x24/0x30
            test-5994  [000] ...1  1528.223286: ext4_mark_inode_dirty: dev 259,0 ino 13 caller __ext4_new_inode+0x1108/0x1338
            test-5994  [000] ...1  1528.223291: ext4_allocate_inode: dev 259,0 ino 13 dir 2 mode 0102620
            test-5994  [000] ...1  1528.223312: ext4_es_lookup_extent_enter: dev 259,0 ino 2 lblk 0
            test-5994  [000] ...1  1528.223320: ext4_es_lookup_extent_exit: dev 259,0 ino 2 found 1 [0/1) 1549 W0x10
            test-5994  [000] ...1  1528.223347: ext4_mark_inode_dirty: dev 259,0 ino 2 caller add_dirent_to_buf+0x170/0x1dc
            test-5994  [000] ...1  1528.223355: ext4_mark_inode_dirty: dev 259,0 ino 13 caller ext4_add_nondir+0x34/0x7c
            test-5994  [000] ...1  1528.223375: jbd2_handle_stats: dev 259,0 tid 36 type 4 line_no 2460 interval 0 sync 0 requested_blocks 35 dirtied_blocks 4
            test-5994  [000] ...1  1528.223413: ext4_sync_file_enter: dev 259,0 ino 13 parent 2 datasync 0
           <...>-578   [002] ...1  1528.223833: jbd2_start_commit: dev 259,0 transaction 36 sync 0
           <...>-578   [002] ...2  1528.223842: jbd2_commit_locking: dev 259,0 transaction 36 sync 0
           <...>-578   [002] ...3  1528.223860: jbd2_checkpoint_stats: dev 259,0 tid 34 chp_time 0 forced_to_close 0 written 0 dropped 5
           <...>-578   [002] ...3  1528.223865: jbd2_drop_transaction: dev 259,0 transaction 34 sync 0
           <...>-578   [002] ...2  1528.223885: jbd2_commit_flushing: dev 259,0 transaction 36 sync 0
           <...>-578   [002] ...1  1528.223896: jbd2_commit_logging: dev 259,0 transaction 36 sync 0
           <...>-578   [002] ...1  1528.223911: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 78
           <...>-578   [002] ...1  1528.223914: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
           <...>-578   [002] ...1  1528.223923: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 78 len 1 flags
           <...>-578   [002] ...1  1528.223936: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
           <...>-578   [002] ...1  1528.223944: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 78 pblk 601 len 1 mflags M ret 1
           <...>-578   [002] ...1  1528.223952: ext4_es_insert_extent: dev 259,0 ino 8 es [78/1) mapped 601 status W
    jbd2/sda16-8-578   [002] ...1  1528.224035: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 79
    jbd2/sda16-8-578   [002] ...1  1528.224037: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-578   [002] ...1  1528.224091: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 79 len 1 flags
    jbd2/sda16-8-578   [002] ...1  1528.224092: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-578   [002] ...1  1528.224093: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 79 pblk 602 len 1 mflags M ret 1
    jbd2/sda16-8-578   [002] ...1  1528.224094: ext4_es_insert_extent: dev 259,0 ino 8 es [79/1) mapped 602 status W
    jbd2/sda16-8-578   [002] ...1  1528.224109: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 80
    jbd2/sda16-8-578   [002] ...1  1528.224110: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-578   [002] ...1  1528.224112: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 80 len 1 flags
    jbd2/sda16-8-578   [002] ...1  1528.224113: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-578   [002] ...1  1528.224114: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 80 pblk 603 len 1 mflags M ret 1
    jbd2/sda16-8-578   [002] ...1  1528.224115: ext4_es_insert_extent: dev 259,0 ino 8 es [80/1) mapped 603 status W
    jbd2/sda16-8-578   [002] ...1  1528.224118: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 81
    jbd2/sda16-8-578   [002] ...1  1528.224120: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-578   [002] ...1  1528.224121: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 81 len 1 flags
    jbd2/sda16-8-578   [002] ...1  1528.224122: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-578   [002] ...1  1528.224124: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 81 pblk 604 len 1 mflags M ret 1
    jbd2/sda16-8-578   [002] ...1  1528.224125: ext4_es_insert_extent: dev 259,0 ino 8 es [81/1) mapped 604 status W
    jbd2/sda16-8-578   [002] ...1  1528.224132: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 82
    jbd2/sda16-8-578   [002] ...1  1528.224133: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-578   [002] ...1  1528.224134: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 82 len 1 flags
    jbd2/sda16-8-578   [002] ...1  1528.224136: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-578   [002] ...1  1528.224137: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 82 pblk 605 len 1 mflags M ret 1
    jbd2/sda16-8-578   [002] ...1  1528.224138: ext4_es_insert_extent: dev 259,0 ino 8 es [82/1) mapped 605 status W
    jbd2/sda16-8-578   [002] ...1  1528.241560: ext4_es_lookup_extent_enter: dev 259,0 ino 8 lblk 83
    jbd2/sda16-8-578   [002] ...1  1528.241657: ext4_es_lookup_extent_exit: dev 259,0 ino 8 found 0 [0/0) 0
    jbd2/sda16-8-578   [002] ...1  1528.241668: ext4_ext_map_blocks_enter: dev 259,0 ino 8 lblk 83 len 1 flags
    jbd2/sda16-8-578   [002] ...1  1528.241684: ext4_ext_show_extent: dev 259,0 ino 8 lblk 0 pblk 523 len 1024
    jbd2/sda16-8-578   [002] ...1  1528.241693: ext4_ext_map_blocks_exit: dev 259,0 ino 8 flags  lblk 83 pblk 606 len 1 mflags M ret 1
    jbd2/sda16-8-578   [002] ...1  1528.241702: ext4_es_insert_extent: dev 259,0 ino 8 es [83/1) mapped 606 status W
    jbd2/sda16-8-578   [002] ...2  1528.242772: jbd2_run_stats: dev 259,0 tid 36 wait 0 request_delay 0 running 0 locked 0 flushing 0 logging 20 handle_count 1 blocks 4 blocks_logged 5
    jbd2/sda16-8-578   [002] ...1  1528.242808: jbd2_end_commit: dev 259,0 transaction 36 sync 0 head 25
            test-5994  [003] ...1  1528.242873: ext4_sync_file_exit: dev 259,0 ino 13 ret 0
```