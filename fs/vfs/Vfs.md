Linux Virtual File System
================================================================================

Overview
--------------------------------------------------------------------------------

https://github.com/leeminghao/doc-linux/blob/master/filesystem/fs/vfs.txt

VFS的作用
--------------------------------------------------------------------------------

虚拟文件系统: 也可以称为虚拟文件系统转换(Virtual Filesystem Switch, VFS),是一个内核软件层,
用来处理与UNIX标准文件系统相关的所有系统调用.

VFS支持的文件系统类型:
* 磁盘文件系统: Ext2, Ext3, NTFS等.
* 网络文件系统: NFS, Coda, AFS, CIFS等.
* 特殊文件系统: /proc

基于磁盘的文件系统通常存放在硬件块设备中,如硬盘,软盘或者CD-ROM. Linux VFS的一个有用特点是能够处理如/dev/loop0这样的虚拟块设备,
这种设备可以用来安装普通文件所在的文件系统.

**注意**: 当一个文件系统被安装在某一个目录上时,在符文见系统中的目录内容不再是可访问的,因为任何路径(包括安装点),都将引用已安装的
文件系统.但是,当被安装文件系统卸载时,原目录的内容又可再现.

VFS除了能为所有文件系统的实现提供一个通用接口外,还具有另一个与系统性能相关的重要作用,最近最长使用的目录项对象被存放在所谓目录项
高速缓存(dentry cache)的磁盘高速缓存中,一般来说,磁盘高速缓存(disk cache)属于软件机制,它允许内核将原本存放在磁盘上的某些信息放到
RAM中,以便对这些数据的进一步访问能快速进行,而不必慢速访问磁盘本身.

通用文件模型
--------------------------------------------------------------------------------

* 超级块对象(superblock object): 存放已安装文件系统的有关信息. 对基于磁盘的文件系统,这类对象通常对应于存放在磁盘上的文件系统控制块.
* 索引节点对象(inode object): 存放关于具体文件的一般信息. 对基于磁盘的文件系统,这类对象通常对应于存放在磁盘上的文件控制块.
* 文件对象(file object): 存放打开文件与进程之间进行交互的有关信息. 这类信息仅当进程访问文件期间存在于内核内存中.
* 目录项对象(dentry object): 存放目录项与对应文件进行链接的有关信息. 每个磁盘文件系统都以自己特有的方式将该类信息存在磁盘上.

例子: 三个不同进程已经打开同一个文件,其中两个文件使用同一个硬链接,在这种情况下:

其中每个进程都使用自己的文件对象, 但只需要两个目录项对象,每个硬链接对应一个目录项对象.这两个目录项对象指向同一个索引节点对象,该索引节点
对象标识超级块对象,以及随后的普通磁盘文件.

VFS的注册
--------------------------------------------------------------------------------

首先,在内核启动过程,会初始化rootfs文件系统,rootfs和tmpfs都是内存中的文件系统,其类型为ramfs.
然后会把这个rootf挂载到根目录. 其代码如下:

## start_kernel

path: init/main.c
```
asmlinkage void __init start_kernel(void)
{
    char * command_line;
    extern const struct kernel_param __start___param[], __stop___param[];
    ......
    /* 初始化dache和inode */
    vfs_caches_init_early();
    ......
    /* 调用vfs_caches_init函数来初始化VFS */
    vfs_caches_init(totalram_pages);
    ......
}
```

## vfs_caches_init_early

path: fs/dcaches.c
```
void __init vfs_caches_init_early(void)
{
    /* 负责初始化dcahes相关的数据结构 */
    dcache_init_early();
    /* 负责初始化inode相关的数据结构 */
    inode_init_early();
}
```

## dcache_init_early

path: fs/dcaches.c
```
static void __init dcache_init_early(void)
{
    unsigned int loop;

    /* If hashes are distributed across NUMA nodes, defer
     * hash allocation until vmalloc space is available.
     */
     if (hashdist)
        return;

    dentry_hashtable =
        alloc_large_system_hash("Dentry cache",
            sizeof(struct hlist_bl_head),
            dhash_entries,
            13,
            HASH_EARLY,
            &d_hash_shift,
            &d_hash_mask,
            0,
            0);

    for (loop = 0; loop < (1U << d_hash_shift); loop++)
        INIT_HLIST_BL_HEAD(dentry_hashtable + loop);
}
```

## inode_init_early

path: fs/inode.c
```
/*
 * Initialize the waitqueues and inode hash table.
 */
void __init inode_init_early(void)
{
    unsigned int loop;

    /* If hashes are distributed across NUMA nodes, defer
     * hash allocation until vmalloc space is available.
     */
     if (hashdist)
        return;

     inode_hashtable =
         alloc_large_system_hash("Inode-cache",
             sizeof(struct hlist_head),
             ihash_entries,
             14,
             HASH_EARLY,
             &i_hash_shift,
             &i_hash_mask,
             0,
             0);

    for (loop = 0; loop < (1U << i_hash_shift); loop++)
        INIT_HLIST_HEAD(&inode_hashtable[loop]);
}
```
两个函数都是调用alloc_large_system_hash函数分别为dentry_hashtable和inode_hashtable分配空间.

## vfs_caches_init

path:

```
void __init vfs_caches_init(unsigned long mempages)
{
    unsigned long reserve;

    /* Base hash sizes on available memory, with a reserve equal to
       150% of current kernel size */

    reserve = min((mempages - nr_free_pages()) * 3/2, mempages - 1);
    mempages -= reserve;

    names_cachep = kmem_cache_create("names_cache", PATH_MAX, 0,
        SLAB_HWCACHE_ALIGN|SLAB_PANIC, NULL);

    dcache_init();
    inode_init();
    files_init(mempages);

    mnt_init();

    bdev_cache_init();
    chrdev_init();
}
```

## mnt_init

```
void __init mnt_init(void)
{
    unsigned u;
    int err;

    mnt_cache = kmem_cache_create("mnt_cache", sizeof(struct mount),
        0, SLAB_HWCACHE_ALIGN | SLAB_PANIC, NULL);

    mount_hashtable = alloc_large_system_hash("Mount-cache",
        sizeof(struct hlist_head),
        mhash_entries, 19,
        0,
        &m_hash_shift, &m_hash_mask, 0, 0);
    mountpoint_hashtable = alloc_large_system_hash("Mountpoint-cache",
        sizeof(struct hlist_head),
        mphash_entries, 19,
        0,
        &mp_hash_shift, &mp_hash_mask, 0, 0);

   if (!mount_hashtable || !mountpoint_hashtable)
       panic("Failed to allocate mount hash table\n");

   for (u = 0; u <= m_hash_mask; u++)
       INIT_HLIST_HEAD(&mount_hashtable[u]);
       for (u = 0; u <= mp_hash_mask; u++)
           INIT_HLIST_HEAD(&mountpoint_hashtable[u]);

   kernfs_init();

   err = sysfs_init();
   if (err)
       printk(KERN_WARNING "%s: sysfs_init error: %d\n",
       __func__, err);
   fs_kobj = kobject_create_and_add("fs", NULL);
   if (!fs_kobj)
       printk(KERN_WARNING "%s: kobj create error\n", __func__);

   init_rootfs();
   init_mount_tree();
}
```

## init_rootfs VS init_mount_tree

这两个函数用于安装根文件系统,具体实现见:
https://github.com/leeminghao/doc-linux/blob/master/filesystem/rootfs/RootFS.md

VFS系统调用的实现
-------------------------------------------------------------------------------

## open

open系统调用的服务例程为sys_open函数,最终是通过调用do_sys_open函数来实现的,如下所示:

#### do_sys_open

path: fs/open.c
```
/* filename: 要打开文件的路径名; flags: 访问模式的一些标志.
 * mode: 文件被创建所需要的许可权位掩码mode.
 * 如果该系统调用成功,就返回一个文件描述符,也就是指向文件对象的指针数组
 * current->files->fd中分配给新文件的索引.
 */
long do_sys_open(int dfd, const char __user *filename, int flags, umode_t mode)
{
	struct open_flags op;
	int fd = build_open_flags(flags, mode, &op);
	struct filename *tmp;

	if (fd)
		return fd;

        /* 1. 调用getname()从进程地址空间读取该文件的路径名 */
	tmp = getname(filename);
	if (IS_ERR(tmp))
		return PTR_ERR(tmp);
        /* 2.调用get_unused_fd()在current->files->fd中查找一个空的位置.相应的索引(新文件描述符)存放在fd局部变量中 */
	fd = get_unused_fd_flags(flags);
	if (fd >= 0) {
		struct file *f = do_filp_open(dfd, tmp, &op);
		if (IS_ERR(f)) {
			put_unused_fd(fd);
			fd = PTR_ERR(f);
		} else {
			fsnotify_open(f);
			fd_install(fd, f);
		}
	}
	putname(tmp);
	return fd;
}
```

#### build_open_flags

build_open_flags函数将参数flags和mode添加到open_flags数据结构中.

path: fs/open.c
```
static inline int build_open_flags(int flags, umode_t mode, struct open_flags *op)
{
	int lookup_flags = 0;
	int acc_mode;

	if (flags & (O_CREAT | __O_TMPFILE))
		op->mode = (mode & S_IALLUGO) | S_IFREG;
	else
		op->mode = 0;

	/* Must never be set by userspace */
	flags &= ~FMODE_NONOTIFY & ~O_CLOEXEC;

	/*
	 * O_SYNC is implemented as __O_SYNC|O_DSYNC.  As many places only
	 * check for O_DSYNC if the need any syncing at all we enforce it's
	 * always set instead of having to deal with possibly weird behaviour
	 * for malicious applications setting only __O_SYNC.
	 */
	if (flags & __O_SYNC)
		flags |= O_DSYNC;

	if (flags & __O_TMPFILE) {
		if ((flags & O_TMPFILE_MASK) != O_TMPFILE)
			return -EINVAL;
		acc_mode = MAY_OPEN | ACC_MODE(flags);
		if (!(acc_mode & MAY_WRITE))
			return -EINVAL;
	} else if (flags & O_PATH) {
		/*
		 * If we have O_PATH in the open flag. Then we
		 * cannot have anything other than the below set of flags
		 */
		flags &= O_DIRECTORY | O_NOFOLLOW | O_PATH;
		acc_mode = 0;
	} else {
		acc_mode = MAY_OPEN | ACC_MODE(flags);
	}

	op->open_flag = flags;

	/* O_TRUNC implies we need access checks for write permissions */
	if (flags & O_TRUNC)
		acc_mode |= MAY_WRITE;

	/* Allow the LSM permission hook to distinguish append
	   access from general write access. */
	if (flags & O_APPEND)
		acc_mode |= MAY_APPEND;

	op->acc_mode = acc_mode;

	op->intent = flags & O_PATH ? 0 : LOOKUP_OPEN;

	if (flags & O_CREAT) {
		op->intent |= LOOKUP_CREATE;
		if (flags & O_EXCL)
			op->intent |= LOOKUP_EXCL;
	}

	if (flags & O_DIRECTORY)
		lookup_flags |= LOOKUP_DIRECTORY;
	if (!(flags & O_NOFOLLOW))
		lookup_flags |= LOOKUP_FOLLOW;
	op->lookup_flags = lookup_flags;
	return 0;
}
```

#### do_filp_open

调用do_filp_open函数,传递给它的参数有路径名和包含flags和mode的数据结构open_flags.

path: fs/namei.c
```
struct file *do_filp_open(int dfd, struct filename *pathname,
		const struct open_flags *op)
{
	struct nameidata nd;
	int flags = op->lookup_flags;
	struct file *filp;

	filp = path_openat(dfd, pathname, &nd, op, flags | LOOKUP_RCU);
	if (unlikely(filp == ERR_PTR(-ECHILD)))
		filp = path_openat(dfd, pathname, &nd, op, flags);
	if (unlikely(filp == ERR_PTR(-ESTALE)))
		filp = path_openat(dfd, pathname, &nd, op, flags | LOOKUP_REVAL);
	return filp;
}
```

#### path_openat

path: fs/namei.c

```
static struct file *path_openat(int dfd, struct filename *pathname,
		struct nameidata *nd, const struct open_flags *op, int flags)
{
	struct file *base = NULL;
	struct file *file;
	struct path path;
	int opened = 0;
	int error;

	file = get_empty_filp();
	if (IS_ERR(file))
		return file;

	file->f_flags = op->open_flag;

	if (unlikely(file->f_flags & __O_TMPFILE)) {
		error = do_tmpfile(dfd, pathname, nd, flags, op, file, &opened);
		goto out;
	}

	error = path_init(dfd, pathname->name, flags | LOOKUP_PARENT, nd, &base);
	if (unlikely(error))
		goto out;

	current->total_link_count = 0;
	error = link_path_walk(pathname->name, nd);
	if (unlikely(error))
		goto out;

	error = do_last(nd, &path, file, op, &opened, pathname);
	while (unlikely(error > 0)) { /* trailing symlink */
		struct path link = path;
		void *cookie;
		if (!(nd->flags & LOOKUP_FOLLOW)) {
			path_put_conditional(&path, nd);
			path_put(&nd->path);
			error = -ELOOP;
			break;
		}
		error = may_follow_link(&link, nd);
		if (unlikely(error))
			break;
		nd->flags |= LOOKUP_PARENT;
		nd->flags &= ~(LOOKUP_OPEN|LOOKUP_CREATE|LOOKUP_EXCL);
		error = follow_link(&link, nd, &cookie);
		if (unlikely(error))
			break;
		error = do_last(nd, &path, file, op, &opened, pathname);
		put_link(nd, &link, cookie);
	}
out:
	if (nd->root.mnt && !(nd->flags & LOOKUP_ROOT))
		path_put(&nd->root);
	if (base)
		fput(base);
	if (!(opened & FILE_OPENED)) {
		BUG_ON(!error);
		put_filp(file);
	}
	if (unlikely(error)) {
		if (error == -EOPENSTALE) {
			if (flags & LOOKUP_RCU)
				error = -ECHILD;
			else
				error = -ESTALE;
		}
		file = ERR_PTR(error);
	}
	return file;
}
```

Blog
-------------------------------------------------------------------------------
* http://www.ibm.com/developerworks/cn/linux/l-vfs/ (解析Linux中的VFS文件系统机制)
* http://blog.csdn.net/yunsongice/article/details/5683859 (把Linux中的VFS对象串联起来)