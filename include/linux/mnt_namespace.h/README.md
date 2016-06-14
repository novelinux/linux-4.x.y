MNT Namespace
========================================

Mount namespace通过隔离文件系统挂载点对隔离文件系统提供支持，它是历史上第一个Linux namespace，
所以它的标识位比较特殊，就是CLONE_NEWNS。隔离后，不同mount namespace中的文件结构发生变化也互不
影响。
你可以通过/proc/[pid]/mounts查看到所有挂载在当前namespace中的文件系统，还可以通过
/proc/[pid]/mountstats看到mount namespace中文件设备的统计信息，包括挂载文件的名字、
文件系统类型、挂载位置等等。

进程在创建mount namespace时，会把当前的文件结构复制给新的namespace。新namespace中的所有mount
操作都只影响自身的文件系统，而对外界不会产生任何影响。这样做非常严格地实现了隔离，但是某些情况
可能并不适用。比如父节点namespace中的进程挂载了一张CD-ROM，这时子节点namespace拷贝的目录结构就
无法自动挂载上这张CD-ROM，因为这种操作会影响到父节点的文件系统。

2006 年引入的挂载传播（mount propagation）解决了这个问题，挂载传播定义了挂载对象（mount object）
之间的关系，系统用这些关系决定任何挂载对象中的挂载事件如何传播到其他挂载对象
所谓传播事件，是指由一个挂载对象的状态变化导致的其它挂载对象的挂载与解除挂载动作的事件。

### 共享关系(share relationship)

如果两个挂载对象具有共享关系，那么一个挂载对象中的挂载事件会传播到另一个挂载对象，反之亦然。

### 从属关系(slave relationship)

如果两个挂载对象形成从属关系，那么一个挂载对象中的挂载事件会传播到
另一个挂载对象，但是反过来不行；在这种关系中，从属对象是事件的接收者。
一个挂载状态可能为如下的其中一种：

* 共享挂载（shared）
* 从属挂载（slave）
* 共享/从属挂载（shared and slave）
* 私有挂载（private）
* 不可绑定挂载（unbindable）

传播事件的挂载对象称为共享挂载（shared mount）;接收传播事件的挂载对象称为从属挂载（slave mount）。
既不传播也不接收传播事件的挂载对象称为私有挂载（private mount）。另一种特殊的挂载对象称为不可绑定
的挂载（unbindable mount），它们与私有挂载相似，但是不允许执行绑定挂载，即创建mount namespace时
这块文件对象不可被复制。

共享挂载的应用场景非常明显，就是为了文件数据的共享所必须存在的一种挂载方式；从属挂载更大的意义在于
某些“只读”场景；私有挂载其实就是纯粹的隔离，作为一个独立的个体而存在；不可绑定挂载则有助于防止没有
必要的文件拷贝，如某个用户数据目录，当根目录被递归式的复制时，用户目录无论从隐私还是实际用途考虑
都需要有一个不可被复制的选项。

Data Structure
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/fs/mount.h/struct_mnt_namespace.md

Sample
----------------------------------------

1.共用同一个MNT namespace

```
root@cancro:/ # ps | grep shell
1|root@cancro:/ # ps | grep sh
root      228   2     0      0     bdi_writeb 00000000 S flush-179:0
root      237   231   3036   1152  sys_rt_sig b6de4c38 S /system/bin/sh
root@cancro:/ # ls -l /proc/237/ns
lrwxrwxrwx root     root              2016-02-19 10:52 mnt -> mnt:[4026531840]
lrwxrwxrwx root     root              2016-02-19 10:52 net -> net:[4026533493]
root@cancro:/ # ps | grep recovery
root      214   1     32528  8076  futex_wait 000483f4 S /sbin/recovery
root@cancro:/ # ls -l /proc/214/ns
lrwxrwxrwx root     root              2016-02-19 10:50 mnt -> mnt:[4026531840]
lrwxrwxrwx root     root              2016-02-19 10:50 net -> net:[4026533493]
```

可以看到shell进程同recovery进程属于同一个MNT namespace. 我们可以看到其挂载的文件系统信息如下所示:

```
root@cancro:/ # cat /proc/237/mounts
rootfs / rootfs rw,seclabel 0 0
tmpfs /dev tmpfs rw,seclabel,nosuid,relatime,size=819200k,nr_inodes=174882,mode=755 0 0
devpts /dev/pts devpts rw,seclabel,relatime,mode=600 0 0
proc /proc proc rw,relatime 0 0
sysfs /sys sysfs rw,seclabel,relatime 0 0
selinuxfs /sys/fs/selinux selinuxfs rw,relatime 0 0
tmpfs /tmp tmpfs rw,seclabel,relatime,size=931392k,nr_inodes=174882 0 0
/dev/block/platform/msm_sdcc.1/by-name/system /system ext4 rw,seclabel,relatime,data=ordered 0 0
/dev/block/platform/msm_sdcc.1/by-name/cache /cache ext4 rw,seclabel,nosuid,nodev,noatime,data=ordered 0 0
root@cancro:/ # cat /proc/214/mounts
rootfs / rootfs rw,seclabel 0 0
tmpfs /dev tmpfs rw,seclabel,nosuid,relatime,size=819200k,nr_inodes=174882,mode=755 0 0
devpts /dev/pts devpts rw,seclabel,relatime,mode=600 0 0
proc /proc proc rw,relatime 0 0
sysfs /sys sysfs rw,seclabel,relatime 0 0
selinuxfs /sys/fs/selinux selinuxfs rw,relatime 0 0
tmpfs /tmp tmpfs rw,seclabel,relatime,size=931392k,nr_inodes=174882 0 0
/dev/block/platform/msm_sdcc.1/by-name/system /system ext4 rw,seclabel,relatime,data=ordered 0 0
/dev/block/platform/msm_sdcc.1/by-name/cache /cache ext4 rw,seclabel,nosuid,nodev,noatime,data=ordered 0 0
```

接下来我们在shell进程中挂载一个新的分区userdata,可以发现两个进程中都有.

```
root@cancro:/ # cat /proc/237/mounts
rootfs / rootfs rw,seclabel 0 0
tmpfs /dev tmpfs rw,seclabel,nosuid,relatime,size=819200k,nr_inodes=174882,mode=755 0 0
devpts /dev/pts devpts rw,seclabel,relatime,mode=600 0 0
proc /proc proc rw,relatime 0 0
sysfs /sys sysfs rw,seclabel,relatime 0 0
selinuxfs /sys/fs/selinux selinuxfs rw,relatime 0 0
tmpfs /tmp tmpfs rw,seclabel,relatime,size=931392k,nr_inodes=174882 0 0
/dev/block/platform/msm_sdcc.1/by-name/system /system ext4 rw,seclabel,relatime,data=ordered 0 0
/dev/block/platform/msm_sdcc.1/by-name/cache /cache ext4 rw,seclabel,nosuid,nodev,noatime,data=ordered 0 0
/dev/block/platform/msm_sdcc.1/by-name/userdata /data ext4 rw,seclabel,relatime,data=ordered 0 0
root@cancro:/ # cat /proc/214/mounts
rootfs / rootfs rw,seclabel 0 0
tmpfs /dev tmpfs rw,seclabel,nosuid,relatime,size=819200k,nr_inodes=174882,mode=755 0 0
devpts /dev/pts devpts rw,seclabel,relatime,mode=600 0 0
proc /proc proc rw,relatime 0 0
sysfs /sys sysfs rw,seclabel,relatime 0 0
selinuxfs /sys/fs/selinux selinuxfs rw,relatime 0 0
tmpfs /tmp tmpfs rw,seclabel,relatime,size=931392k,nr_inodes=174882 0 0
/dev/block/platform/msm_sdcc.1/by-name/system /system ext4 rw,seclabel,relatime,data=ordered 0 0
/dev/block/platform/msm_sdcc.1/by-name/cache /cache ext4 rw,seclabel,nosuid,nodev,noatime,data=ordered 0 0
/dev/block/platform/msm_sdcc.1/by-name/userdata /data ext4 rw,seclabel,relatime,data=ordered 0 0
```

2.使用分离的MNT namespace

```
root@cancro:/ # ps | grep sh
root      227   2     0      0     bdi_writeb 00000000 S flush-179:0
root      236   230   3036   1136  sys_rt_sig b6ddac38 S /system/bin/sh
root@cancro:/ # ps | grep recovery
root      214   1     32528  8080  futex_wait 00048424 S /sbin/recovery
root@cancro:/ # ls -l /proc/214/ns
lrwxrwxrwx root     root              2016-02-19 11:07 mnt -> mnt:[4026534022]
lrwxrwxrwx root     root              2016-02-19 11:07 net -> net:[4026533493]
root@cancro:/ # ls -l /proc/236/ns
lrwxrwxrwx root     root              2016-02-19 11:07 mnt -> mnt:[4026531840]
lrwxrwxrwx root     root              2016-02-19 11:07 net -> net:[4026533493]
root@cancro:/ # cat /proc/214/mounts
rootfs / rootfs rw,seclabel 0 0
tmpfs /dev tmpfs rw,seclabel,nosuid,relatime,size=819200k,nr_inodes=174882,mode=755 0 0
devpts /dev/pts devpts rw,seclabel,relatime,mode=600 0 0
proc /proc proc rw,relatime 0 0
sysfs /sys sysfs rw,seclabel,relatime 0 0
selinuxfs /sys/fs/selinux selinuxfs rw,relatime 0 0
tmpfs /tmp tmpfs rw,seclabel,relatime,size=931392k,nr_inodes=174882 0 0
/dev/block/platform/msm_sdcc.1/by-name/system /system ext4 rw,seclabel,relatime,data=ordered 0 0
/dev/block/platform/msm_sdcc.1/by-name/cache /cache ext4 rw,seclabel,nosuid,nodev,noatime,data=ordered 0 0
root@cancro:/ # cat /proc/236/mounts
rootfs / rootfs rw,seclabel 0 0
tmpfs /dev tmpfs rw,seclabel,nosuid,relatime,size=819200k,nr_inodes=174882,mode=755 0 0
devpts /dev/pts devpts rw,seclabel,relatime,mode=600 0 0
proc /proc proc rw,relatime 0 0
sysfs /sys sysfs rw,seclabel,relatime 0 0
selinuxfs /sys/fs/selinux selinuxfs rw,relatime 0 0
tmpfs /tmp tmpfs rw,seclabel,relatime,size=931392k,nr_inodes=174882 0 0
/dev/block/platform/msm_sdcc.1/by-name/system /system ext4 rw,seclabel,relatime,data=ordered 0 0
/dev/block/platform/msm_sdcc.1/by-name/userdata /data                         <
root@cancro:/ # cat /proc/214/mounts
rootfs / rootfs rw,seclabel 0 0
tmpfs /dev tmpfs rw,seclabel,nosuid,relatime,size=819200k,nr_inodes=174882,mode=755 0 0
devpts /dev/pts devpts rw,seclabel,relatime,mode=600 0 0
proc /proc proc rw,relatime 0 0
sysfs /sys sysfs rw,seclabel,relatime 0 0
selinuxfs /sys/fs/selinux selinuxfs rw,relatime 0 0
tmpfs /tmp tmpfs rw,seclabel,relatime,size=931392k,nr_inodes=174882 0 0
/dev/block/platform/msm_sdcc.1/by-name/system /system ext4 rw,seclabel,relatime,data=ordered 0 0
/dev/block/platform/msm_sdcc.1/by-name/cache /cache ext4 rw,seclabel,nosuid,nodev,noatime,data=ordered 0 0
```

该实例是在recovery进程中添加了如下类似语句:

```
unshare(CLONE_NEWNS)
```

用来将recovery进程使用了一个和shell进程不一样的MNT namespace, 可以看到在这两个不同mnt namespace中
所挂载的文件系统是不一致的.
