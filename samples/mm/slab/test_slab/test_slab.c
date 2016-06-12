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
        array[i]->id = 0x1;
    }
    kmem_cache_destroy(test_slab_cachep);
}

module_init(test_slab_init);
module_exit(test_slab_exit);

MODULE_LICENSE("GPL");
