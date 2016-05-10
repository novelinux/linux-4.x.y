parse_one
========================================

path: kernel/params.c
```
static int parse_one(char *param,
             char *val,
             const char *doing,
             const struct kernel_param *params,
             unsigned num_params,
             s16 min_level,
             s16 max_level,
             int (*handle_unknown)(char *param, char *val,
                     const char *doing))
{
    unsigned int i;
    int err;

    /* Find parameter */
    for (i = 0; i < num_params; i++) {
        if (parameq(param, params[i].name)) {
            if (params[i].level < min_level
                || params[i].level > max_level)
                return 0;
            /* No one handled NULL, so do it here. */
            if (!val &&
                !(params[i].ops->flags & KERNEL_PARAM_OPS_FL_NOARG))
                return -EINVAL;
            pr_debug("handling %s with %p\n", param,
                params[i].ops->set);
            mutex_lock(&param_lock);
            param_check_unsafe(&params[i]);
            err = params[i].ops->set(val, &params[i]);
            mutex_unlock(&param_lock);
            return err;
        }
    }

    if (handle_unknown) {
        pr_debug("doing %s: %s='%s'\n", doing, param, val);
        return handle_unknown(param, val, doing);
    }

    pr_debug("Unknown argument '%s'\n", param);
    return -ENOENT;
}
```

handle_unknown
----------------------------------------

在parse_early_options函数中handle_unknown函数为do_early_param用来处理
传递给内核的参数.

https://github.com/novelinux/linux-4.x.y/tree/master/init/main.c/do_early_param.md
