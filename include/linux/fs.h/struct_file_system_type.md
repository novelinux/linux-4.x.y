struct file_system_type
========================================

用于描述文件系统的结构定义如下：

name
----------------------------------------

path: include/linux/fs.h
```
struct file_system_type {
    const char *name;
```

name保存了文件系统的名称，是一个字符串(因此包含了例如reiserfs、ext3等类似的值)。

fs_flags
----------------------------------------

```
    int fs_flags;
```

fs_flags是使用的标志，例如标明只读装载、禁止setuid/setgid操作或进行其他的微调。

mount
----------------------------------------

```
#define FS_REQUIRES_DEV        1
#define FS_BINARY_MOUNTDATA    2
#define FS_HAS_SUBTYPE         4
#define FS_USERNS_MOUNT        8    /* Can be mounted by userns root */
#define FS_USERNS_DEV_MOUNT    16 /* A userns mount does not imply MNT_NODEV */
#define FS_USERNS_VISIBLE      32    /* FS must already be visible */
#define FS_RENAME_DOES_D_MOVE  32768    /* FS will handle d_move() during rename() internally. */
    struct dentry *(*mount) (struct file_system_type *, int,
               const char *, void *);
```

kill_sb
----------------------------------------

```
    void (*kill_sb) (struct super_block *);
```

kill_super在不再需要某个文件系统类型时执行清理工作。

owner
----------------------------------------

```
    struct module *owner;
```

owner是一个指向module结构的指针，仅当文件系统以模块形式加载时，owner才包含
有意义的值(NULL指针表示文件系统已经持久编译到内核中).

next
----------------------------------------

```
    struct file_system_type * next;
```

各个可用的文件系统通过next成员连接起来，这里无法利用标准的链表功能，因为这是一个单链表。

fs_supers
----------------------------------------

```
    struct hlist_head fs_supers;
```

对于每个已经装载的文件系统，在内存中都创建了一个超级块结构。该结构保存了文件系统它本身和装载点
的有关信息。由于可以装载几个同一类型的文件系统(最好的例子是home和root分区，二者的文件系统类型
通常相同)，同一文件系统类型可能对应了多个超级块结构，这些超级块聚集在一个链表中。fs_supers是
对应的表头。

s_lock_key
----------------------------------------

```
    struct lock_class_key s_lock_key;
    struct lock_class_key s_umount_key;
    struct lock_class_key s_vfs_rename_key;
    struct lock_class_key s_writers_key[SB_FREEZE_LEVELS];

    struct lock_class_key i_lock_key;
    struct lock_class_key i_mutex_key;
    struct lock_class_key i_mutex_dir_key;
};
```