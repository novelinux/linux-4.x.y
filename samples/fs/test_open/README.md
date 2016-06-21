open
========================================

src
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/samples/open/open.c

result
----------------------------------------

```
root@gemini:/ # /data/local/tmp/open /cache/test.txt
root@gemini:/ # ls -l /cache/test.txt
-rw-r--r-- root     root            0 2016-06-17 07:15 test.txt
root@gemini:/ # stat /cache/test.txt
  File: `/cache/test.txt'
  Size: 0        Blocks: 0       IO Blocks: 4096        regular empty file
Device: 80dh      Inode: 11       Links: 1
Access: (644/-rw-r--r--) Uid: (0/    root)      Gid: (0/    root)
Access: 2016-06-17 07:15:45.179439339
Modify: 2016-06-17 07:15:45.179439339
Change: 2016-06-17 07:15:45.179439339
```

trace
----------------------------------------

```
open-3612  [001] ...1   383.455870: ext4_request_inode: dev 8,13 dir 2 mode 0100644
open-3612  [001] ...1   383.455928: ext4_journal_start: dev 8,13 blocks, 35 rsv_blocks, 0 caller __ext4_new_inode+0x5c4/0x1180
open-3612  [001] ...1   383.456077: ext4_mark_inode_dirty: dev 8,13 ino 11 caller ext4_ext_tree_init+0x24/0x30
open-3612  [001] ...1   383.456086: ext4_mark_inode_dirty: dev 8,13 ino 11 caller __ext4_new_inode+0xfc4/0x1180
open-3612  [001] ...1   383.456095: ext4_allocate_inode: dev 8,13 ino 11 dir 2 mode 0100644
open-3612  [001] ...1   383.456103: ext4_es_lookup_extent_enter: dev 8,13 ino 2 lblk 0
open-3612  [001] ...1   383.456108: ext4_es_lookup_extent_exit: dev 8,13 ino 2 found 1 [0/1) 1556 W
open-3612  [001] ...1   383.456124: ext4_mark_inode_dirty: dev 8,13 ino 2 caller add_dirent_to_buf+0x1a0/0x1ec
open-3612  [001] ...1   383.456136: ext4_mark_inode_dirty: dev 8,13 ino 11 caller ext4_add_nondir+0x34/0x78
```
