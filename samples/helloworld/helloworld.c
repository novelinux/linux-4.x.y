#define pr_fmt(fmt) "helloworld: " fmt

#include <linux/module.h>

static int helloworld_init(void)
{
    pr_info("hello world\n");
    return 0;
}

static void helloworld_exit(void)
{
    pr_info("Good bye\n");
}

module_init(helloworld_init);
module_exit(helloworld_exit);

MODULE_LICENSE("GPL");
