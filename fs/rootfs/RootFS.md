Linux File System - rootfs
================================================================================

What is rootfs?
--------------------------------------------------------------------------------

https://github.com/leeminghao/doc-linux/blob/master/filesystem/rootfs/ramfs-rootfs-initramfs.txt

History
--------------------------------------------------------------------------------

在早期的Linux系统中,一般就只有软盘或者硬盘被用来作为Linux的根文件系统,因此很容易把这些设备的驱动程序集成到内核中.
但是现在根文件系统可能保存在各种存储设备上, 包括SCSI, SATA,U盘等等. 因此把这些设备驱动程序全部编译到内核中显得不太方便.
利用udevd可以实现实现内核模块的自动加载, 因此我们希望根文件系统的设备驱动程序也能够实现自动加载. 但是这里有一个矛盾,
udevd是一个可执行文件, 在根文件系统被挂载前, 是不可能执行udevd的, 但是如果udevd没有启动, 那就无法自动根据根目录来加载系统设备的驱动程序
同时也无法在/dev目录下建立相应的设备节点. 为了解决这个矛盾,于是出现了initrd(bootloader initialized RAMdisk).
initrd是一个被压缩过的小型根目录, 这个目录中包含了启动阶段中必须的驱动模块, 可执行文件和启动脚本. 包括上面提到的udevd,
当系统启动的时候, booloader会把initrd文件读到内存中,然后把initrd的起始地址告诉内核.内核在运行过程中会解压initrd,
然后把initrd挂载为根目录,然后执行根目录中的/initrc脚本,您可以在这个脚本中运行initrd中的udevd,让它来自动加载设备驱动程序以及
在/dev目录下建立必要的设备节点. 在udevd自动加载磁盘驱动程序之后，就可以mount真正的根目录，并切换到这个根目录中。
可以通过下面的方法来制作一个initrd文件。

```
# dd if=/dev/zero of=initrd.img bs=4k count=1024
# mkfs.ext2 -F initrd.img
# mount -o loop initrd.img  /mnt
# cp -r  miniroot/* /mnt
# umount /mnt
# gzip -9 initrd.img
```

通过上面的命令, 我们制作了一个4M的initrd, 其中miniroot就是一个根目录. 最后我们得到一个名为initrd.img.gz的压缩文件.
利用initrd内核在启动阶段可以顺利的加载设备驱动程序,然而initrd存在以下缺点:
* initrd大小是固定的,例如上面的压缩之前的initrd大小是4M(4k*1024), 假设您的根目录(上例中的miniroot/)总大小仅仅是1M,
  它仍然要占用4M的空间.如果您在dd阶段指定大小为1M,后来发现不够用的时候,必须按照上面的步骤重新来一次.
* initrd是一个虚拟的块设备,在上面的例子中,您可是使用fdisk对这个虚拟块设备进行分区.在内核中,对块设备的读写还要经过缓冲区管理模块,
  也就是说,当内核读取initrd中的文件内容时,缓冲区管理层会认为下层的块设备速度比较慢,因此会启用预读和缓存功能.这样initrd本身就在内存中,
  同时块设备缓冲区管理层还会保存一部分内容.

为了避免上述缺点,于是出现了initramfs,它的作用和initrd类似,您可以使用下面的方法来制作一个initramfs:

```
# find miniroot/ | cpio -c -o > initrd.img
# gzip initrd.img
```

这样得到的initrd.img大小是可变的,它取决于您的小型根目录miniroot/的总大小,由于首选使用cpio把根目录进行打包，
因此这个initramfs又被称为cpio initrd. 在系统启动阶段, bootloader除了从磁盘上机制内核镜像bzImage之外,还要加载
initrd.img.gz,然后把initrd.img.gz的起始地址传递给内核. 能不能把这两个文件合二为一呢? 答案是肯定的, 在Linux2.6的内核中,
可以把initrd.img.gz链接到内核文件(ELF格式)的一个特殊的数据段中, 这个段的名字为.init.ramfs.
其中全局变量__initramfs_start和__initramfs_end分别指向这个数据段的起始地址和结束地址.
内核启动时会对.init.ramfs段中的数据进行解压, 然后使用它作为临时的根文件系统.

别看这个过程复杂，只需要在make menuconfig中配置以下选项就可以了：

```
General setup  --->
    [*] Initial RAM filesystem and RAM disk (initramfs/initrd) support
    (../miniroot/)    Initramfs source file(s)
```

其中../miniroot/就是我们的小型根目录. 这样就只需要一个内核镜像文件就可以了. 内核在启动过程中, 必须对以下几种情况进行处理：
如果.init.ramfs数据段大小不为0(initramfs_end - initramfs_start != 0), 就说明这是initrd集成在内核数据段中.并且是cpio的initrd.
initrd是由bootloader加载到内存中的,这时bootloader会把起始地址和结束地址传递给内核,内核中的全局initrd_start和initrd_end分别
指向initrd的起始地址和结束地址。现在内核还需要判断这个initrd是新式的cpio格式的initrd还是旧的initrd.

安装根文件系统
--------------------------------------------------------------------------------

安装根文件系统是系统初始化的关键部分.这是一个相当复杂的过程,因为Linux内核允许根文件系统存放在很多不同的地方,比如:
硬盘分区,软盘,通过NFS共享的远程文件系统,甚至保存到ramdisk中(RAM中的虚拟块设备).
当系统启动时,内核就要在变量ROOT_DEV中寻找包含根文件系统的磁盘主设备号.当编译内核时,或者向最初的bootloader传递一个root
选项时,根文件系统可以被指定为/dev目录下的一个设备文件.类似的,根文件系统的安装标志存放在root_mountflags变量中.用户可以指定
这些标志,或者通过对已编译的内核映像使用rdev外部程序，或者想最初的bootloader程序传递一个合适的rootflags选项来达到.

安装根文件系统分为两个阶段:

## Stage1

内核安装特殊rootfs文件系统,该文件系统仅提供一个作为初始安装点的空目录.

#### init_rootfs

path: init/do_mounts.c
```
int __init init_rootfs(void)
{
    /* 调用register_filesystem函数注册rootfs文件系统 */
    int err = register_filesystem(&rootfs_fs_type);

    if (err)
        return err;

    if (IS_ENABLED(CONFIG_TMPFS) && !saved_root_name[0] &&
        (!root_fs_names || strstr(root_fs_names, "tmpfs"))) {
        err = shmem_init();
        is_tmpfs = true;
    } else {
        err = init_ramfs_fs();
    }

    if (err)
        unregister_filesystem(&rootfs_fs_type);

    return err;
}
```

#### register_filesystem

path: fs/filesystems.c
```
/**
 * register_filesystem - register a new filesystem
 * @fs: the file system structure
 *
 * Adds the file system passed to the list of file systems the kernel
 * is aware of for mount and other syscalls. Returns 0 on success,
 * or a negative errno code on an error.
 *
 * The &struct file_system_type that is passed is linked into the kernel
 * structures and must not be freed until the file system has been
 * unregistered.
 */

int register_filesystem(struct file_system_type * fs)
{
    int res = 0;
    struct file_system_type ** p;

    BUG_ON(strchr(fs->name, '.'));
    if (fs->next)
        return -EBUSY;
    write_lock(&file_systems_lock);
    p = find_filesystem(fs->name, strlen(fs->name));
    if (*p)
        res = -EBUSY;
    else
        *p = fs;
    write_unlock(&file_systems_lock);
    return res;
}
```

#### find_filesystem

```
static struct file_system_type **find_filesystem(const char *name, unsigned len)
{
    struct file_system_type **p;
    for (p=&file_systems; *p; p=&(*p)->next)
    if (strlen((*p)->name) == len &&
        strncmp((*p)->name, name, len) == 0)
            break;
    return p;
}
```

#### rootfs_fs_type

path: init/do_mounts.c
```
static struct file_system_type rootfs_fs_type = {
    .name ="rootfs",
    .mount = rootfs_mount,
    .kill_sb = kill_litter_super,
};
```

init_mount_tree函数执行如下操作:

#### init_mount_tree

path: fs/namespace.c
```
static void __init init_mount_tree(void)
{
    struct vfsmount *mnt;
    struct mnt_namespace *ns;
    struct path root;
    struct file_system_type *type;

    /* 调用get_fs_type在文件系统类型链表中搜索并确定"rootfs"的名字的位置,
     * 返回局部变量type中对应file_system_type描述符的地址 */
    type = get_fs_type("rootfs");
    if (!type)
       panic("Can't find rootfs type");

    mnt = vfs_kern_mount(type, 0, "rootfs", NULL);
    put_filesystem(type);
    if (IS_ERR(mnt))
        panic("Can't create rootfs");

    /* 调用create_mnt_ns函数为进程0的命名空间分配一个mnt_namespace对象 */
    ns = create_mnt_ns(mnt);
    if (IS_ERR(ns))
        panic("Can't allocate initial namespace");

    /* 并将它插入到init_task.nsproxy->mnt_ns中去 */
    init_task.nsproxy->mnt_ns = ns;
    get_mnt_ns(ns);

    root.mnt = mnt;
    root.dentry = mnt->mnt_root;

    /* 将进程0的根目录和当前工作目录设置为根文件系统 */
    set_fs_pwd(current->fs, &root);
    set_fs_root(current->fs, &root);
}
```

调用vfs_kern_mount函数,把字符串"rootfs"作为文件系统类型参数传递给它,并把该函数返回的新安装文件系统描述符
的地址保存在mnt局部变量中.

#### vfs_kern_mount

path: fs/namespace.c
```
/* 参数: type - 要安装的文件系统的类型名.
 * flags - 安装标志.
 * name - 存放文件系统的块设备的路径名.
 * data - 指向传递给文件系统的mount_fs方法的附加数据的指针 */
struct vfsmount *
vfs_kern_mount(struct file_system_type *type, int flags, const char *name, void *data)
{
    struct mount *mnt;
    struct dentry *root;

    if (!type)
        return ERR_PTR(-ENODEV);

    /* 调用alloc_vfsmnt分配一个新的已安装文件系统的描述符,并将它的地址存放在mnt局部变量中 */
    mnt = alloc_vfsmnt(name);
    if (!mnt)
       return ERR_PTR(-ENOMEM);

    if (flags & MS_KERNMOUNT)
    mnt->mnt.mnt_flags = MNT_INTERNAL;

    /* 调用mount_fs来加载根文件系统的超级块信息 */
    root = mount_fs(type, flags, name, data);
    if (IS_ERR(root)) {
       free_vfsmnt(mnt);
       return ERR_CAST(root);
    }

    /* 将mnt->mnt.mnt_root的字段初始化为与文件系统根目录对应的目录项对象的地址,
     * 并增加该目录项对象的引用计数值 */
    mnt->mnt.mnt_root = root;
    /* 用新超级块对象的地址初始化mnt->mnt.mnt_sb字段 */
    mnt->mnt.mnt_sb = root->d_sb;
    mnt->mnt_mountpoint = mnt->mnt.mnt_root;
    /* 用mnt的值初始化mnt->mnt_parent字段 */
    mnt->mnt_parent = mnt;
    lock_mount_hash();
    list_add_tail(&mnt->mnt_instance, &root->d_sb->s_mounts);
    unlock_mount_hash();
    /* 返回已安装文件系统对象的地址mnt */
    return &mnt->mnt;
}
```

接下来调用mount_fs函数来mount根文件系统, 如下所示:

#### mount_fs

path: fs/super.c
```
struct dentry *
mount_fs(struct file_system_type *type, int flags, const char *name, void *data)
{
	struct dentry *root;
	struct super_block *sb;
	char *secdata = NULL;
	int error = -ENOMEM;

	if (data && !(type->fs_flags & FS_BINARY_MOUNTDATA)) {
		secdata = alloc_secdata();
		if (!secdata)
			goto out;

		error = security_sb_copy_data(data, secdata);
		if (error)
			goto out_free_secdata;
	}

        /* 调用"root"文件类型描述符指定的mount函数来获取根目录项,
         * 在这里mount指针指向的是rootfs_mount函数. */
	root = type->mount(type, flags, name, data);
	if (IS_ERR(root)) {
		error = PTR_ERR(root);
		goto out_free_secdata;
	}
	sb = root->d_sb;
	BUG_ON(!sb);
	WARN_ON(!sb->s_bdi);
	WARN_ON(sb->s_bdi == &default_backing_dev_info);
	sb->s_flags |= MS_BORN;

	error = security_sb_kern_mount(sb, flags, secdata);
	if (error)
		goto out_sb;

	/*
	 * filesystems should never set s_maxbytes larger than MAX_LFS_FILESIZE
	 * but s_maxbytes was an unsigned long long for many releases. Throw
	 * this warning for a little while to try and catch filesystems that
	 * violate this rule.
	 */
	WARN((sb->s_maxbytes < 0), "%s set sb->s_maxbytes to "
		"negative value (%lld)\n", type->name, sb->s_maxbytes);

	up_write(&sb->s_umount);
	free_secdata(secdata);
	return root;
out_sb:
	dput(root);
	deactivate_locked_super(sb);
out_free_secdata:
	free_secdata(secdata);
out:
	return ERR_PTR(error);
}
```

#### rootfs_mount

path: init/do_mounts.c
```
static bool is_tmpfs;
static struct dentry *rootfs_mount(struct file_system_type *fs_type,
	int flags, const char *dev_name, void *data)
{
	static unsigned long once;
	void *fill = ramfs_fill_super;

	if (test_and_set_bit(0, &once))
		return ERR_PTR(-ENODEV);

	if (IS_ENABLED(CONFIG_TMPFS) && is_tmpfs)
		fill = shmem_fill_super;

        /* 最终调用mount_nodev函数来获取rootfs的超级块并把根目录项指针返回到上一级函数 */
	return mount_nodev(fs_type, flags, data, fill);
}
```

#### mount_nodev

path: fs/super.c
```
struct dentry *mount_nodev(struct file_system_type *fs_type,
	int flags, void *data,
	int (*fill_super)(struct super_block *, void *, int))
{
	int error;
        /* 1. 调用sget()函数分配新的超级块,传递set_anon_super函数的地址作为参数.
         * 接下来,用合适的方式设置超级块的s_dev字段; 主设备号,次设备号不同于其它
         * 已安装的特殊文件系统的次设备号
         */
	struct super_block *s = sget(fs_type, NULL, set_anon_super, flags, NULL);

	if (IS_ERR(s))
		return ERR_CAST(s);

        /* fill_super函数指针指定为了ramfs_fill_super,在此,调用该函数来分配索引节点对象
         * 和对应的目录项对象,并填充超级块字段值. 由于rootfs是一种特殊文件系统, 没有磁盘
         * 超级块, 因此只需执行两个超级块操作
         */
	error = fill_super(s, data, flags & MS_SILENT ? 1 : 0);
	if (error) {
		deactivate_locked_super(s);
		return ERR_PTR(error);
	}
	s->s_flags |= MS_ACTIVE;
        /* 调用dget函数返回对应的根文件系统的根目录项对象 */
	return dget(s->s_root);
}
```

#### ramfs_fill_suer

path: fs/ramfs/inode.c
```
int ramfs_fill_super(struct super_block *sb, void *data, int silent)
{
	struct ramfs_fs_info *fsi;
	struct inode *inode;
	int err;

	save_mount_options(sb, data);

	fsi = kzalloc(sizeof(struct ramfs_fs_info), GFP_KERNEL);
	sb->s_fs_info = fsi;
	if (!fsi)
		return -ENOMEM;

	err = ramfs_parse_options(data, &fsi->mount_opts);
	if (err)
		return err;

	sb->s_maxbytes		= MAX_LFS_FILESIZE;
	sb->s_blocksize		= PAGE_CACHE_SIZE;
	sb->s_blocksize_bits	= PAGE_CACHE_SHIFT;
	sb->s_magic		= RAMFS_MAGIC;
	sb->s_op		= &ramfs_ops;
	sb->s_time_gran		= 1;

	inode = ramfs_get_inode(sb, NULL, S_IFDIR | fsi->mount_opts.mode, 0);
	sb->s_root = d_make_root(inode);
	if (!sb->s_root)
		return -ENOMEM;

	return 0;
}
```

#### ramfs_get_inode

path: fs/ramfs/inode.c
```
struct inode *ramfs_get_inode(struct super_block *sb,
				const struct inode *dir, umode_t mode, dev_t dev)
{
	struct inode * inode = new_inode(sb);

	if (inode) {
		inode->i_ino = get_next_ino();
		inode_init_owner(inode, dir, mode);
		inode->i_mapping->a_ops = &ramfs_aops;
		inode->i_mapping->backing_dev_info = &ramfs_backing_dev_info;
		mapping_set_gfp_mask(inode->i_mapping, GFP_HIGHUSER);
		mapping_set_unevictable(inode->i_mapping);
		inode->i_atime = inode->i_mtime = inode->i_ctime = CURRENT_TIME;
		switch (mode & S_IFMT) {
		default:
			init_special_inode(inode, mode, dev);
			break;
		case S_IFREG:
			inode->i_op = &ramfs_file_inode_operations;
			inode->i_fop = &ramfs_file_operations;
			break;
		case S_IFDIR:
			inode->i_op = &ramfs_dir_inode_operations;
			inode->i_fop = &simple_dir_operations;

			/* directory inodes start off with i_nlink == 2 (for "." entry) */
			inc_nlink(inode);
			break;
		case S_IFLNK:
			inode->i_op = &page_symlink_inode_operations;
			break;
		}
	}
	return inode;
}
```

## Stage2

内核在空目录上安装实际的根文件系统.
**注意:** 内核为何要在安装实际根文件系统之前安装rootfs文件系统呢?
  rootfs文件系统允许内核容易地改变实际根文件系统.事实上,在某些情况下,内核逐个地安装和卸载几个根文件系统.

根文件系统安装操作的第二阶段是由内核在系统初始化即将结束时进行的.根据内核被编译时所选择的选项,和内核装入
程序所传递的启动选项,可以由集中方法安装实际根文件系统.为了简单起见,我们只考虑磁盘文件系统的情况,它的设备
文件名已经通过"root"启动参数传递给内核.同时我们假定除了rootfs文件系统以外,没有使用其他初始特殊文件系统.

start_kernel-->rest_init-->kernel_init-->kernel_init_freeable-->prepare_namespace.

#### prepare_namespace

path: init/do_mounts.c
```
/*
 * Prepare the namespace - decide what/where to mount, load ramdisks, etc.
 */
void __init prepare_namespace(void)
{
	int is_floppy;

	if (root_delay) {
		printk(KERN_INFO "Waiting %d sec before mounting root device...\n",
		       root_delay);
		ssleep(root_delay);
	}

	/*
	 * wait for the known devices to complete their probing
	 *
	 * Note: this is a potential source of long boot delays.
	 * For example, it is not atypical to wait 5 seconds here
	 * for the touchpad of a laptop to initialize.
	 */
	wait_for_device_probe();

	md_run_setup();

        /* 把root_device_name变量设置为从参数"root"中获取的设备文件名,同样把ROOT_DEV变量设置为
         * 同一设备文件的主设备号和次设备号
         */
	if (saved_root_name[0]) {
		root_device_name = saved_root_name;
		if (!strncmp(root_device_name, "mtd", 3) ||
		    !strncmp(root_device_name, "ubi", 3)) {
			mount_block_root(root_device_name, root_mountflags);
			goto out;
		}
		ROOT_DEV = name_to_dev_t(root_device_name);
		if (strncmp(root_device_name, "/dev/", 5) == 0)
			root_device_name += 5;
	}

	if (initrd_load())
		goto out;

	/* wait for any asynchronous scanning to complete */
	if ((ROOT_DEV == 0) && root_wait) {
		printk(KERN_INFO "Waiting for root device %s...\n",
			saved_root_name);
		while (driver_probe_done() != 0 ||
			(ROOT_DEV = name_to_dev_t(saved_root_name)) == 0)
			msleep(100);
		async_synchronize_full();
	}

	is_floppy = MAJOR(ROOT_DEV) == FLOPPY_MAJOR;

	if (is_floppy && rd_doload && rd_load_disk(0))
		ROOT_DEV = Root_RAM0;

        /* 2.调用mount_root函数. */
	mount_root();
out:
	devtmpfs_mount("dev");
        /* 3.移动rootfs文件系统根目录上的已安装文件系统的安装点 */
	sys_mount(".", "/", NULL, MS_MOVE, NULL);
	sys_chroot(".");
}
```

**注意**:rootfs特殊文件系统并没有被卸载,它只是隐藏在基于磁盘的根文件系统下了.

#### mount_root

path: init/do_mounts.c
```
void __init mount_root(void)
{
#ifdef CONFIG_ROOT_NFS
	if (ROOT_DEV == Root_NFS) {
		if (mount_nfs_root())
			return;

		printk(KERN_ERR "VFS: Unable to mount root fs via NFS, trying floppy.\n");
		ROOT_DEV = Root_FD0;
	}
#endif
#ifdef CONFIG_BLK_DEV_FD
	if (MAJOR(ROOT_DEV) == FLOPPY_MAJOR) {
		/* rd_doload is 2 for a dual initrd/ramload setup */
		if (rd_doload==2) {
			if (rd_load_disk(1)) {
				ROOT_DEV = Root_RAM1;
				root_device_name = NULL;
			}
		} else
			change_floppy("root floppy");
	}
#endif
#ifdef CONFIG_BLOCK
	create_dev("/dev/root", ROOT_DEV);
	mount_block_root("/dev/root", root_mountflags);
#endif
}
```

#### create_dev

path: init/do_mounts.h
```
static inline int create_dev(char *name, dev_t dev)
{
	sys_unlink(name);
        /* 调用sys_mknode函数在rootfs初始根文件系统中创建设备文件"/dev/root",
         * 其主,次设备号与存放在ROOT_DEV中的一样 */
	return sys_mknod(name, S_IFBLK|0600, new_encode_dev(dev));
}
```

Blog
--------------------------------------------------------------------------------
* http://blog.csdn.net/zzobin/article/details/7722838 (Linux内核Ramdisk机制)
* http://www.linuxsir.org/bbs/thread336103.html (精通initramfs的构建)
* http://blog.linux.org.tw/~jserv/archives/001954.html (深入理解Linux 2.6的initramfs机制)
* http://www.ibm.com/developerworks/cn/linux/l-k26initrd/ (Linux 2.6内核的Initrd机制解析)
* http://kissthink.com/archive/gou-jian-i-n-i-t-r-a-m-f-s-wen-jian-xi-tong.html