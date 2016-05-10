cgroup_init_early
========================================

cgroup: 它的全称为control group.即一组进程的行为控制.比如,我们限制进程/bin/sh的CPU使用为20%.
我们就可以建一个cpu占用为20%的cgroup. 然后将/bin/sh进程添加到这个cgroup中.当然,一个cgroup
可以有多个进程.

path: kernel/cgroup.c
```
/**
 * cgroup_init_early - cgroup initialization at system boot
 *
 * Initialize cgroups at system boot, and initialize any
 * subsystems that request early init.
 */
int __init cgroup_init_early(void)
{
    static struct cgroup_sb_opts __initdata opts;
    struct cgroup_subsys *ss;
    int i;

    init_cgroup_root(&cgrp_dfl_root, &opts);
    cgrp_dfl_root.cgrp.self.flags |= CSS_NO_REF;

    RCU_INIT_POINTER(init_task.cgroups, &init_css_set);

    for_each_subsys(ss, i) {
        WARN(!ss->css_alloc || !ss->css_free || ss->name || ss->id,
             "invalid cgroup_subsys %d:%s css_alloc=%p css_free=%p name:id=%d:%s\n",
             i, cgroup_subsys_name[i], ss->css_alloc, ss->css_free,
             ss->id, ss->name);
        WARN(strlen(cgroup_subsys_name[i]) > MAX_CGROUP_TYPE_NAMELEN,
             "cgroup_subsys_name %s too long\n", cgroup_subsys_name[i]);

        ss->id = i;
        ss->name = cgroup_subsys_name[i];
        if (!ss->legacy_name)
            ss->legacy_name = cgroup_subsys_name[i];

        if (ss->early_init)
            cgroup_init_subsys(ss, true);
    }
    return 0;
}
```