DEBUG
========================================

Documentation
----------------------------------------

path: Documentation/vm/slub.txt

samples
----------------------------------------

path: test_slab.c
```
#define pr_fmt(fmt) "test_slab: " fmt

#include <linux/module.h>
#include <linux/slab.h>

struct test_slab_struct {
    int  id;
    char name[20];
    char address[50];
};

static struct kmem_cache *test_slab_cachep;

#define TEST_SLAB_SIZE 1

static struct test_slab_struct *array[TEST_SLAB_SIZE];

static int test_slab_init(void)
{
    int i;

    pr_info("test_slab_init\n");

    test_slab_cachep = kmem_cache_create("test_slab_cache",
                                         sizeof (struct test_slab_struct),
                                         __alignof__(struct test_slab_struct),
                                         0, NULL);
    if (test_slab_cachep == NULL) {
        pr_err("failed to create test_slab_cache\n");
        return -1;
    }

    for (i = 0; i < TEST_SLAB_SIZE; ++i) {
        array[i] = kmem_cache_alloc(test_slab_cachep, GFP_KERNEL);
        if (array[i] == NULL) {
            pr_err("failed to alloc the '%d' test_slab_struct.\n", i);
            return -1;
        }
    }

    return 0;
}

static void test_slab_exit(void)
{
    int i;

    pr_info("test_slab_exit\n");

    for (i = 0; i < TEST_SLAB_SIZE; ++i) {
        kmem_cache_free(test_slab_cachep, array[i]);
    }
    kmem_cache_destroy(test_slab_cachep);
}

module_init(test_slab_init);
module_exit(test_slab_exit);

MODULE_LICENSE("GPL");
```

### cmdline

```
cmdline: slub_debug=FPZ
```

### use after free

```
static void test_slab_exit(void)
{
    int i;

    pr_info("test_slab_exit\n");

    for (i = 0; i < TEST_SLAB_SIZE; ++i) {
        kmem_cache_free(test_slab_cachep, array[i]);
        array[i]->id = 0x1;
    }
    kmem_cache_destroy(test_slab_cachep);
}
```

```
[  138.701261] =============================================================================
[  138.709260] BUG test_slab_cache (Tainted: G        WC    ): Poison overwritten
[  138.716527] -----------------------------------------------------------------------------
[  138.716527]
[  138.726200] INFO: 0xffffffc051d1f000-0xffffffc051d1f003. First byte 0x1 instead of 0x6b
[  138.734149] INFO: Slab 0xffffffba49040550 objects=42 used=0 fp=0xffffffc051d1f000 flags=0x0080
[  138.742834] INFO: Object 0xffffffc051d1f000 @offset=0 fp=0xffffffc051d1ff60
[  138.742834]
[  138.751115] Object ffffffc051d1f000: 01 00 00 00 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b  ....kkkkkkkkkkkk
[  138.760488] Object ffffffc051d1f010: 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b  kkkkkkkkkkkkkkkk
[  138.769639] Object ffffffc051d1f020: 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b  kkkkkkkkkkkkkkkk
[  138.779016] Object ffffffc051d1f030: 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b  kkkkkkkkkkkkkkkk
[  138.788357] Object ffffffc051d1f040: 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b a5              kkkkkkkkkkk.
[  138.797242] Redzone ffffffc051d1f04c: bb bb bb bb                                      ....
[  138.805606] Padding ffffffc051d1f058: 5a 5a 5a 5a 5a 5a 5a 5a                          ZZZZZZZZ
[  138.814261] CPU: 2 PID: 3429 Comm: rmmod Tainted: G    B   WC     3.18.20-g459b3d5-331322-ge174b6e-dirty #15
[  138.824082] Call trace:
[  138.826423] [<ffffffc000088568>] dump_backtrace+0x0/0x270
[  138.831880] [<ffffffc0000887e8>] show_stack+0x10/0x1c
[  138.836860] [<ffffffc000cdec04>] dump_stack+0x74/0xb8
[  138.842017] [<ffffffc00019442c>] print_trailer+0x150/0x164
[  138.847360] [<ffffffc0001944e8>] check_bytes_and_report+0xa8/0x10c
[  138.853540] [<ffffffc0001946a8>] check_object+0x110/0x218
[  138.858875] [<ffffffc0001948fc>] __free_slab+0x14c/0x180
[  138.864292] [<ffffffc00019498c>] discard_slab+0x5c/0x68
[  138.869405] [<ffffffc000197be4>] free_partial+0x78/0x21c
[  138.874720] [<ffffffc000197e34>] __kmem_cache_shutdown+0x3c/0x68
[  138.880806] [<ffffffc0001742c4>] kmem_cache_destroy+0x40/0xa8
[  138.886424] [<ffffffbffc0000c4>] test_slab_exit+0x3c/0x4c [test_slab]
[  138.892865] [<ffffffc000112b5c>] SyS_delete_module+0x150/0x1d0
[  138.898634] FIX test_slab_cache: Restoring 0xffffffc051d1f000-0xffffffc051d1f003=0x6b
```

### double free

```
static void test_slab_exit(void)
{
    int i;

    pr_info("test_slab_exit\n");

    for (i = 0; i < TEST_SLAB_SIZE; ++i) {
        kmem_cache_free(test_slab_cachep, array[i]);
        kmem_cache_free(test_slab_cachep, array[i]);
    }
    kmem_cache_destroy(test_slab_cachep);
}
```

```
[   90.283623] =============================================================================
[   90.291726] BUG test_slab_cache (Tainted: G        WC    ): Object already free
[   90.299005] -----------------------------------------------------------------------------
[   90.299005]
[   90.308652] INFO: Slab 0xffffffba48c600e0 objects=42 used=0 fp=0xffffffc04c2ea000 flags=0x0081
[   90.317237] INFO: Object 0xffffffc04c2ea000 @offset=0 fp=0xffffffc04c2eaf60
[   90.317237]
[   90.325662] Object ffffffc04c2ea000: 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b  kkkkkkkkkkkkkkkk
[   90.334948] Object ffffffc04c2ea010: 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b  kkkkkkkkkkkkkkkk
[   90.344239] Object ffffffc04c2ea020: 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b  kkkkkkkkkkkkkkkk
[   90.353522] Object ffffffc04c2ea030: 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b  kkkkkkkkkkkkkkkk
[   90.362810] Object ffffffc04c2ea040: 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b a5              kkkkkkkkkkk.
[   90.371752] Redzone ffffffc04c2ea04c: bb bb bb bb                                      ....
[   90.380085] Padding ffffffc04c2ea058: 5a 5a 5a 5a 5a 5a 5a 5a                          ZZZZZZZZ
[   90.388769] CPU: 2 PID: 3425 Comm: rmmod Tainted: G    B   WC     3.18.20-g459b3d5-331322-ge174b6e-dirty #15
[   90.398576] Call trace:
[   90.401019] [<ffffffc000088568>] dump_backtrace+0x0/0x270
[   90.406391] [<ffffffc0000887e8>] show_stack+0x10/0x1c
[   90.411430] [<ffffffc000cdec04>] dump_stack+0x74/0xb8
[   90.416461] [<ffffffc00019442c>] print_trailer+0x150/0x164
[   90.421926] [<ffffffc000194584>] object_err+0x38/0x4c
[   90.426960] [<ffffffc0001968f8>] free_debug_processing+0x230/0x300
[   90.433123] [<ffffffc000196a0c>] __slab_free+0x44/0x378
[   90.438332] [<ffffffc000196f0c>] kmem_cache_free+0x1cc/0x25c
[   90.443976] [<ffffffbffc0000bc>] test_slab_exit+0x34/0x4c [test_slab]
[   90.450402] [<ffffffc000112b5c>] SyS_delete_module+0x150/0x1d0
[   90.456396] FIX test_slab_cache: Object at 0xffffffc04c2ea000 not freed
```

slabinfo
----------------------------------------

所有活动缓存的列表保存在/proc/slabinfo中:

```
root@android:/ # cat /proc/slabinfo
slabinfo - version: 2.1
# name            <active_objs> <num_objs> <objsize> <objperslab> <pagesperslab> : tunables <limit> <batchcount> <sharedfactor> : slabdata <active_slabs> <num_slabs> <sharedavail>
ext4_groupinfo_4k     39     39    104   39    1 : tunables    0    0    0 : slabdata      1      1      0
UDPLITEv6              0      0    768   21    4 : tunables    0    0    0 : slabdata      0      0      0
UDPv6                  0      0    768   21    4 : tunables    0    0    0 : slabdata      0      0      0
tw_sock_TCPv6          0      0    192   21    1 : tunables    0    0    0 : slabdata      0      0      0
TCPv6                  0      0   1472   22    8 : tunables    0    0    0 : slabdata      0      0      0
nf_conntrack_expect      0      0    176   23    1 : tunables    0    0    0 : slabdata      0      0      0
nf_conntrack_c1809980      0      0    256   16    1 : tunables    0    0    0 : slabdata      0      0      0
ashmem_area_cache      0      0    296   27    2 : tunables    0    0    0 : slabdata      0      0      0
dm_crypt_io            0      0    104   39    1 : tunables    0    0    0 : slabdata      0      0      0
kcopyd_job             0      0   2808   11    8 : tunables    0    0    0 : slabdata      0      0      0
...
```