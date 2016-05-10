Linux Credentials
================================================================================

Credentials?
--------------------------------------------------------------------------------

https://github.com/leeminghao/doc-linux/blob/master/security/credentials/credentials.txt


Task Credentials
--------------------------------------------------------------------------------

在Linux中,所有的Task Credentials都通过一个名为"struct cred"的结构体引用来保存,每个Task
的task_struct中有一个名为"cred"的指针指向该进程的credential.
一旦credentials集合已经prepare并且commited之后,其一般不会再改变

## 进程凭证描述符(struct cred)

路径: include/linux/cred.h

```
/*
 * The security context of a task - 用来描述一个进程安全性的上下文
 *
 * The parts of the context break down into two categories:
 * 一个进程的安全上下文可以分文如下两类
 *
 *  (1) The objective context of a task.  These parts are used when some other
 *  task is attempting to affect this one.
 *  (1) 进程客观的安全上下文 - 用于控制当其他进程尝试侵袭当前的进程
 *
 *  (2) The subjective context.  These details are used when the task is acting
 *  upon another object, be that a file, a task, a key or whatever.
 *  (2) 进程主观的安全上下文 - 用于控制其访问其他的资源(一个文件, 一个进程等等)
 *
 * Note that some members of this structure belong to both categories - the
 * LSM security pointer for instance.
 *
 * A task has two security pointers.  task->real_cred points to the objective
 * context that defines that task's actual details.  The objective part of this
 * context is used whenever that task is acted upon.
 *
 * task->cred points to the subjective context that defines the details of how
 * that task is going to act upon another object.  This may be overridden
 * temporarily to point to another security context, but normally points to the
 * same context as task->real_cred.
 */
struct cred {
	atomic_t	usage;
#ifdef CONFIG_DEBUG_CREDENTIALS
	atomic_t	subscribers;	/* number of processes subscribed */
	void		*put_addr;
	unsigned	magic;
#define CRED_MAGIC	0x43736564
#define CRED_MAGIC_DEAD	0x44656144
#endif
        /* 1. Traditional UNIX credentials */
        /* 用户和组的实际ID, 标识我们究竟是谁(登录用户的uid和gid). */
	uid_t		uid;		/* real UID of the task */
	gid_t		gid;		/* real GID of the task */
       /* 用户和组保存的ID,由exec函数保存. */
	uid_t		suid;		/* saved UID of the task */
	gid_t		sgid;		/* saved GID of the task */
        /* 用户和组的有效ID, 用于除了对资源(文件)访问以外的所有操作. */
	uid_t		euid;		/* effective UID of the task */
	gid_t		egid;		/* effective GID of the task */
        /* 文件访问的用户和组的有效ID,进程用来决定对资源(文件)的访问权限. */
	uid_t		fsuid;		/* UID for VFS ops */
	gid_t		fsgid;		/* GID for VFS ops */

        /* 2.Secure management flags */
	unsigned	securebits;	/* SUID-less security management */

        /* 3.Capabilities */
	kernel_cap_t	cap_inheritable; /* caps our children can inherit */
	kernel_cap_t	cap_permitted;	/* caps we're permitted */
	kernel_cap_t	cap_effective;	/* caps we can actually use */
	kernel_cap_t	cap_bset;	/* capability bounding set */

        /* 4.Keys and keyrings */
#ifdef CONFIG_KEYS
	unsigned char	jit_keyring;	/* default keyring to attach requested
					 * keys to */
	struct key	*thread_keyring; /* keyring private to this thread */
	struct key	*request_key_auth; /* assumed request_key authority */
	struct thread_group_cred *tgcred; /* thread-group shared credentials */
#endif

        /* 5.LSM */
#ifdef CONFIG_SECURITY
	void		*security;	/* subjective LSM security */
#endif

	struct user_struct *user;	/* real user ID subscription */
	struct user_namespace *user_ns; /* cached user->user_ns */
	struct group_info *group_info;	/* supplementary groups for euid/fsgid */
	struct rcu_head	rcu;		/* RCU deletion hook */
};
```

## idle进程的credential

idle进程是linux中的第一个进程,其进程credential是由内核开发者手动设置的,
idle进程的credential初始化是通过宏RCU_INIT_POINTER来实现的,其声明如下:

#### include/linux/rcupdate.h

```
/* 将init_cred的地址赋值给real_cred和cred指针 */
#define RCU_INIT_POINTER(p, v) \
		p = (typeof(*v) __force __rcu *)(v)
```

#### init_cred的定义

路径: linux/kernel/cred.c

```
/*
 * The initial credentials for the initial task
 */
struct cred init_cred = {
	.usage			= ATOMIC_INIT(4),
#ifdef CONFIG_DEBUG_CREDENTIALS
	.subscribers		= ATOMIC_INIT(2),
	.magic			= CRED_MAGIC,
#endif
	.securebits		= SECUREBITS_DEFAULT,
	.cap_inheritable	= CAP_EMPTY_SET,
	.cap_permitted		= CAP_FULL_SET,
	.cap_effective		= CAP_FULL_SET,
	.cap_bset		= CAP_FULL_SET,
	.user			= INIT_USER,
	.user_ns		= &init_user_ns,
	.group_info		= &init_groups,
#ifdef CONFIG_KEYS
	.tgcred			= &init_tgcred,
#endif
};
```

最终,idle进程的credential如下所示:

```
1.Traditional UNIX credentials:
  uid=0,gid=0; suid=0, sgid=0; euid=0, egid=0, fsuid=0, fsgid=0 (scontext)
  uid=0,gid=0; suid=0, sgid=0; euid=0, egid=0, fsuid=0, fsgid=0 (ocontext)
```

## Fork Credentials

一个新创建的进程的credential是在其父进程在调用fork函数创建其时调用copy_creds函数为其准备的.
调用流程如下所示:

#### copy_process

path: kernel/kernel/fork.c
```
static struct task_struct *copy_process(unsigned long clone_flags,
    unsigned long stack_start,
    struct pt_regs *regs,
    unsigned long stack_size,
    int __user *child_tidptr,
    struct pid *pid,
    int trace)
{
        int retval;
        struct task_struct *p;
        int cgroup_callbacks_done = 0;

        /* 1. 检查clone_flags是否合法 */

        /* 2. 通过调用security_task_create(clone_flags)函数以及稍后的security_task_alloc(p)
         * 函数执行所有附加的安全检查.
         */
         retval = security_task_create(clone_flags);

        /* 3. 调用dup_task_struct为子进程获取进程描述符.
         */
         p = dup_task_struct(current);

        /* 4.得到的进程与父进程内容几乎完全一致，初始化新创建进程 */
        ......
        retval = -EAGAIN;
        if (atomic_read(&p->real_cred->user->processes) >=
           task_rlimit(p, RLIMIT_NPROC)) {
           if (!capable(CAP_SYS_ADMIN) && !capable(CAP_SYS_RESOURCE) &&
               p->real_cred->user != INIT_USER)
                    goto bad_fork_free;
        }
        current->flags &= ~PF_NPROC_EXCEEDED;
        /* 5. 为新建的进程拷贝credentials */
        retval = copy_creds(p, clone_flags);
        if (retval < 0)
            goto bad_fork_free;

        ......

        return p;

        ......
}
```

为新建进程创建credential的函数是copy_cred,其具体实现如下所示:
#### copy_creds

path:kernel/kernel/cred.c
```
/*
 * Copy credentials for the new process created by fork()
 *
 * We share if we can, but under some circumstances we have to generate a new
 * set.
 *
 * The new process gets the current process's subjective credentials as its
 * objective and subjective credentials
 */
int copy_creds(struct task_struct *p, unsigned long clone_flags)
{
#ifdef CONFIG_KEYS
    struct thread_group_cred *tgcred;
#endif
    struct cred *new;
    int ret;

    p->replacement_session_keyring = NULL;

    /* CLONE_THREAD - 把子进程插入到父进程的同一线程组中,并迫使子进程共享父进程的信号描述符 */
    if (
#ifdef CONFIG_KEYS
       !p->cred->thread_keyring &&
#endif
        clone_flags & CLONE_THREAD
       ) {
           /* 将real_cred指针指向cred */
           p->real_cred = get_cred(p->cred);
           get_cred(p->cred);
           alter_cred_subscribers(p->cred, 2);
           kdebug("share_creds(%p{%d,%d})",
                  p->cred, atomic_read(&p->cred->usage),
                  read_cred_subscribers(p->cred));
                  atomic_inc(&p->cred->user->processes);
           return 0;
   }

   /* 1.为新进程准备一个新的struct cred结构体用于保存其credential */
   new = prepare_creds();
   if (!new)
      return -ENOMEM;

   /* 2.以下代码用于初始化新的credential */
   if (clone_flags & CLONE_NEWUSER) {
      ret = create_user_ns(new);
      if (ret < 0)
          goto error_put;
   }

   /* cache user_ns in cred.  Doesn't need a refcount because it will
    * stay pinned by cred->user
    */
    new->user_ns = new->user->user_ns;

#ifdef CONFIG_KEYS
   /* new threads get their own thread keyrings if their parent already
    * had one */
    if (new->thread_keyring) {
       key_put(new->thread_keyring);
       new->thread_keyring = NULL;
       if (clone_flags & CLONE_THREAD)
          install_thread_keyring_to_cred(new);
    }

   /* we share the process and session keyrings between all the threads in
    * a process - this is slightly icky as we violate COW credentials a
    * bit */
    if (!(clone_flags & CLONE_THREAD)) {
       tgcred = kmalloc(sizeof(*tgcred), GFP_KERNEL);
       if (!tgcred) {
          ret = -ENOMEM;
          goto error_put;
       }
       atomic_set(&tgcred->usage, 1);
       spin_lock_init(&tgcred->lock);
       tgcred->process_keyring = NULL;
       tgcred->session_keyring = key_get(new->tgcred->session_keyring);

       release_tgcred(new);
       new->tgcred = tgcred;
   }
#endif

    atomic_inc(&new->user->processes);
    /* 3.将新建的credential描述符挂接到任务描述符的cred和real_cred指针上 */
    p->cred = p->real_cred = get_cred(new);
    alter_cred_subscribers(new, 2);
    validate_creds(new);
    return 0;

error_put:
    put_cred(new);
    return ret;
}
```

下面我们来看prepare_creds函数是如何为新进程准备新建一个"struct cred"结构体来保存进程的credential的.
#### prepare_creds

path: kernel/cred.c

```
/**
 * prepare_creds - Prepare a new set of credentials for modification
 *
 * Prepare a new set of task credentials for modification.  A task's creds
 * shouldn't generally be modified directly, therefore this function is used to
 * prepare a new copy, which the caller then modifies and then commits by
 * calling commit_creds().
 *
 * Preparation involves making a copy of the objective creds for modification.
 *
 * Returns a pointer to the new creds-to-be if successful, NULL otherwise.
 *
 * Call commit_creds() or abort_creds() to clean up.
 */
struct cred *prepare_creds(void)
{
	struct task_struct *task = current;
	const struct cred *old;
	struct cred *new;

	validate_process_creds();
        /* 1.先为指向credential描述符(struct crede)的new指针分配一块内存 */
	new = kmem_cache_alloc(cred_jar, GFP_KERNEL);
	if (!new)
		return NULL;

	kdebug("prepare_creds() alloc %p", new);

        /* 2.获取当前进程的scontext(subjective context)(用于访问资源时候作为安全性验证,保存在task描述符的cred变量中.)
        ** 并将当前进程的scontext赋给新建的struct cred局部变量指针new.
        */
	old = task->cred;
	memcpy(new, old, sizeof(struct cred));

        /* 3.初始化新创建的credential描述符 */
	atomic_set(&new->usage, 1);
	set_cred_subscribers(new, 0);
	get_group_info(new->group_info);
	get_uid(new->user);

#ifdef CONFIG_KEYS
	key_get(new->thread_keyring);
	key_get(new->request_key_auth);
	atomic_inc(&new->tgcred->usage);
#endif

#ifdef CONFIG_SECURITY
	new->security = NULL;  /* 将LSM初始化为NULL */
#endif

        /* 4.根据当前内核配置的rules调用对应的cred_parepare函数来初始化credential描述符 */
	if (security_prepare_creds(new, old, GFP_KERNEL) < 0)
		goto error;
	validate_creds(new);
	return new;  /* 返回新建的credential 描述符 */

error:
	abort_creds(new);
	return NULL;
}
```

综上可知,父进程调用fork函数创建子进程以后,子进程和父进程的credentials一模一样.
init进程作为一个内核线程(调用kernel_thread函数创建,最终也是调用do_fork函数来从父进程)
就和其父进程idle进程的credentials完全一样.