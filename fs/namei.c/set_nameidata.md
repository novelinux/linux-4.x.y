set_nameidata
========================================

配置struct nameidata实例，并保存到当前进程的nameidata中.

path: fs/namei.c
```
static void set_nameidata(struct nameidata *p, int dfd, struct filename *name)
{
    struct nameidata *old = current->nameidata;
    p->stack = p->internal;
    p->dfd = dfd;
    p->name = name;
    p->total_link_count = old ? old->total_link_count : 0;
    p->saved = old;
    current->nameidata = p;
}
```