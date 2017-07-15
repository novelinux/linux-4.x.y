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

## stack

```
<4>[   70.194863] CPU: 0 PID: 4428 Comm: test-open-write Tainted: G        W       4.4.21-perf-g6a9ee37d-05916-g45a6982-dirty #21
<4>[   70.194913] Hardware name: Qualcomm Technologies, Inc. MSM 8998 v2.1 MTP (DT)
<4>[   70.194926] Call trace:
<4>[   70.194967] [<ffffff80080875f4>] dump_backtrace+0x0/0x1c0
<4>[   70.194985] [<ffffff80080877c8>] show_stack+0x14/0x1c
<4>[   70.195009] [<ffffff800837297c>] dump_stack+0x8c/0xac
<4>[   70.195035] [<ffffff800825ed88>] ext4_es_lookup_extent+0x20/0x25c
<4>[   70.195054] [<ffffff8008225464>] ext4_map_blocks+0x50/0x3f4
<4>[   70.195064] [<ffffff8008225858>] ext4_getblk+0x50/0x174
<4>[   70.195082] [<ffffff800822f480>] ext4_find_entry+0x288/0x4d0
<4>[   70.195095] [<ffffff800822f774>] ext4_lookup+0xac/0x254
<4>[   70.195116] [<ffffff80081bf214>] lookup_real+0x34/0x54
<4>[   70.195128] [<ffffff80081c3134>] path_openat+0x590/0xbd4
<4>[   70.195141] [<ffffff80081c4374>] do_filp_open+0x3c/0x84
<4>[   70.195159] [<ffffff80081b6140>] do_sys_open+0x164/0x1fc
<4>[   70.195171] [<ffffff80081b6210>] SyS_openat+0x10/0x18
<4>[   70.195185] [<ffffff8008084630>] el0_svc_naked+0x24/0x28
<4>[   70.202868] CPU: 0 PID: 4428 Comm: test-open-write Tainted: G        W       4.4.21-perf-g6a9ee37d-05916-g45a6982-dirty #21
<4>[   70.202881] Hardware name: Qualcomm Technologies, Inc. MSM 8998 v2.1 MTP (DT)
<4>[   70.202887] Call trace:
<4>[   70.202901] [<ffffff80080875f4>] dump_backtrace+0x0/0x1c0
<4>[   70.202911] [<ffffff80080877c8>] show_stack+0x14/0x1c
<4>[   70.202922] [<ffffff800837297c>] dump_stack+0x8c/0xac
<4>[   70.202932] [<ffffff800825ed88>] ext4_es_lookup_extent+0x20/0x25c
<4>[   70.202940] [<ffffff8008225464>] ext4_map_blocks+0x50/0x3f4
<4>[   70.202945] [<ffffff8008225858>] ext4_getblk+0x50/0x174
<4>[   70.202951] [<ffffff8008225988>] ext4_bread+0xc/0x78
<4>[   70.202958] [<ffffff800822db18>] __ext4_read_dirblock+0x3c/0x2c4
<4>[   70.202964] [<ffffff8008230cc8>] ext4_add_entry+0x140/0x300
<4>[   70.202970] [<ffffff8008230ea8>] ext4_add_nondir+0x20/0x7c
<4>[   70.202976] [<ffffff8008231148>] ext4_create+0xd0/0x174
<4>[   70.202985] [<ffffff80081c1b98>] vfs_create+0x90/0xec
<4>[   70.202990] [<ffffff80081c319c>] path_openat+0x5f8/0xbd4
<4>[   70.202998] [<ffffff80081c4374>] do_filp_open+0x3c/0x84
<4>[   70.203007] [<ffffff80081b6140>] do_sys_open+0x164/0x1fc
<4>[   70.203013] [<ffffff80081b6210>] SyS_openat+0x10/0x18
<4>[   70.203020] [<ffffff8008084630>] el0_svc_naked+0x24/0x28
<4>[   70.203146] CPU: 0 PID: 4428 Comm: test-open-write Tainted: G        W       4.4.21-perf-g6a9ee37d-05916-g45a6982-dirty #21
<4>[   70.203151] Hardware name: Qualcomm Technologies, Inc. MSM 8998 v2.1 MTP (DT)
<4>[   70.203155] Call trace:
<4>[   70.203161] [<ffffff80080875f4>] dump_backtrace+0x0/0x1c0
<4>[   70.203168] [<ffffff80080877c8>] show_stack+0x14/0x1c
<4>[   70.203175] [<ffffff800837297c>] dump_stack+0x8c/0xac
<4>[   70.203181] [<ffffff800825ed88>] ext4_es_lookup_extent+0x20/0x25c
<4>[   70.203187] [<ffffff8008224b38>] ext4_da_get_block_prep+0x80/0x3ec
<4>[   70.203193] [<ffffff80082236c8>] ext4_block_write_begin+0x148/0x3c0
<4>[   70.203201] [<ffffff8008229704>] ext4_da_write_begin+0x208/0x304
<4>[   70.203211] [<ffffff8008164568>] generic_perform_write+0xc8/0x194
<4>[   70.203217] [<ffffff800816566c>] __generic_file_write_iter+0xcc/0x16c
<4>[   70.203224] [<ffffff800821f6e0>] ext4_file_write_iter+0x230/0x2f4
<4>[   70.203231] [<ffffff80081b661c>] __vfs_write+0xa0/0xd0
<4>[   70.203237] [<ffffff80081b6dd8>] vfs_write+0xac/0x144
<4>[   70.203242] [<ffffff80081b7588>] SyS_write+0x48/0x84
<4>[   70.203248] [<ffffff8008084630>] el0_svc_naked+0x24/0x28
```